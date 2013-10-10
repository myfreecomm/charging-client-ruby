# encoding: utf-8

require 'spec_helper'

describe Charging::ChargeAccount, :vcr do
  let(:domain) { double(:domain, token: 'QNTGvpnYRVC4HbHibDBUIQ==') }
  let(:uuid) { '29e77bc5-0e70-444c-a922-3149e78d905b' }
  let(:attributes) do
    {
      bank: '237',
      name: 'Conta de cobrança',
      agreement_code: '12345',
      portfolio_code: '25',
      account: {number: '12345', digit: '6'},
      agency: {number: '12345', digit: '6'},
      currency: 9
    }
  end

  context 'for new instance' do
    CA_ATTRIBUTES = [
      :bank, :name, :agreement_code, :portfolio_code, :account, :agency,
      :currency, :supplier_name, :address, :sequence_numbers, :advance_days
    ]
    
    let(:response) { double(:response, code: 500) }
    
    subject do
      attributes = Hash[*CA_ATTRIBUTES.map {|attr| [attr, "#{attr} value"] }.flatten]
      
      described_class.new(attributes, domain, response)
    end
    
    CA_ATTRIBUTES.each do |attribute|
      its(attribute) { should eq "#{attribute} value"}
    end
    
    [:uuid, :uri, :etag, :national_identifier].each do |attribute|
      its(attribute) { should be_nil }
    end
    
    its(:domain) { should eq domain }
    its(:last_response) { should eq response }
    its(:errors) { should eq [] }
    
    specify('#persisted?') { expect(subject).to_not be_persisted }
    specify('#deleted?') { expect(subject).to_not be_deleted }
    
    its(:attributes) do
      should eq({
        account: 'account value',
        address: 'address value',
        advance_days: "advance_days value",
        agency: "agency value",
        agreement_code: "agreement_code value",
        bank: "bank value",
        currency: "currency value",
        default_charging_features: nil,
        name: "name value",
        our_number_range: nil,
        portfolio_code: "portfolio_code value",
        sequence_numbers: "sequence_numbers value",
        supplier_name: "supplier_name value",
        zipcode: nil
      })
    end
  end
  
  describe '#create!' do
    it 'should require a domain and load errors' do
      charge_account = described_class.new(attributes, nil)

      expect(charge_account.errors).to be_empty

      expected_error = [StandardError, 'can not create without a domain']
      expect { charge_account.create! }.to raise_error(*expected_error)

      expect(charge_account.errors).to eq ['can not create without a domain']
    end

    context 'when everything is OK' do
      subject { described_class.new(attributes, domain) }

      before do
        VCR.use_cassette('creating a charge account') do
          subject.create!
        end
      end

      [:uuid, :uri, :etag].each do |attribute|
        its(attribute) { should_not be_nil }
      end

      it 'should be persisted' do
        expect(subject).to be_persisted
      end
    end
  end
  
  describe '#destroy!' do
    context 'try delete a charge account with invoices' do
      it 'should raise' do
        VCR.use_cassette('try delete a charge account') do
          charge_account = described_class.find_by_uuid(domain, uuid)
          
          expect { charge_account.destroy! }.to raise_error Charging::Http::LastResponseError
          
          expect(charge_account).to_not be_deleted
          expect(charge_account).to be_persisted
        end
      end
    end

    it 'should delete charge account at API' do
      VCR.use_cassette('deleting a charge account') do
        charge_account = described_class.new(attributes, domain)
        expect { charge_account.create! }.to_not raise_error
        expect(charge_account).to be_persisted
        
        expect { charge_account.destroy! }.to_not raise_error
        expect(charge_account).to be_deleted
        expect(charge_account).to_not be_persisted
      end
    end
  end
  
  describe '#update_attribute!' do
    context 'try update a readonly attribute on charge account' do
      it 'should raise' do
        VCR.use_cassette('try update bank attribute on charge account') do
          charge_account = described_class.find_by_uuid(domain, uuid)
          
          expect(charge_account.bank).to eq '237'
          expect { charge_account.update_attribute! :bank, '341' }.to raise_error Charging::Http::LastResponseError
          expect(charge_account.bank).to eq '237'
        end
      end
    end

    it 'should delete charge account at API' do
      VCR.use_cassette('updating an attribute at charge account') do
        charge_account = described_class.find_by_uuid(domain, uuid)
        
        expect { charge_account.update_attribute! :address, '123 New Address St.' }.to_not raise_error
        expect(charge_account).to be_persisted

        expect(charge_account.address).to eq '123 New Address St.'
      end
    end
  end
  
  describe '#update_attributes!' do
    it 'should delegate to update_attribute! for each attribute' do
      charge_account = described_class.new(attributes, domain)

      charge_account.should_receive(:update_attribute!).exactly(3)
      charge_account.should_receive(:reload_attributes!).once
      
      charge_account.update_attributes!(address: 'New Address', zipcode: '12345', city: 'City')
    end
  end

  describe '.find_all' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'domain required']

      expect { described_class.find_all(nil) }.to raise_error(*expected_error)
    end

    context 'for an account' do
      let(:result) do
        VCR.use_cassette('list available charge-accounts') do
          described_class.find_all(domain)
        end
      end

      it 'should result be a domain collection instance' do
        expect(result).to be_an_instance_of(Charging::ChargeAccount::Collection)
      end

      it 'should contain only one domain' do
        expect(result.size).to_not eq 0
      end

      it 'should contain last response information' do
        expect(result.last_response.code).to eq 200
      end

      context 'on first element result' do
        let(:charge_account) { result.first }

        it 'should be a persisted domain' do
          expect(charge_account).to be_persisted
        end

        it 'should contain etag' do
          expect(charge_account.etag).to_not be_nil
        end

        it 'should contain uuid' do
          expect(charge_account.uuid).to eq uuid
        end

        it 'should contain uri' do
          expect(charge_account.uri).to eq "http://sandbox.charging.financeconnect.com.br/charge-accounts/#{uuid}/"
        end
      end
    end
  end
  
  describe '.find_by_uuid' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'domain required']

      expect { described_class.find_by_uuid(nil, '') }.to raise_error(*expected_error)
    end

    it 'should require an uuid' do
      expected_error = [ArgumentError, 'uuid required']

      expect { described_class.find_by_uuid(domain, nil) }.to raise_error(*expected_error)
    end

    it 'should raise for invalid uuid' do
      VCR.use_cassette('finding invalid charge account') do
        expect { described_class.find_by_uuid(domain, 'invalid-uuid') }.to raise_error Charging::Http::LastResponseError
      end
    end

    it 'should raise if not response to success (200)' do
      response_mock = double('AcceptedResponse', code: 202, to_s: 'AcceptedResponse')

      described_class
        .should_receive(:get_charge_account)
        .with(domain, uuid)
        .and_return(response_mock)

      expect {
        described_class.find_by_uuid(domain, uuid)
      }.to raise_error Charging::Http::LastResponseError, 'AcceptedResponse'
    end

    context 'for a valid uuid' do
      subject do
        VCR.use_cassette('finding a charging account by uuid via domain') do
          described_class.find_by_uuid(domain, uuid)
        end
      end

      it 'should instantiate a charge account' do
        expect(subject).to be_an_instance_of(Charging::ChargeAccount)
      end

      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      its(:uri) { should eq "http://sandbox.charging.financeconnect.com.br/charge-accounts/#{uuid}/" }
      its(:uuid) { should eq uuid }
      its(:etag) { should eq subject.last_response.headers[:etag] }
      its(:national_identifier) { should eq '03.448.307/9170-25' }
      its(:domain) { should eq domain }
    end
  end
end
