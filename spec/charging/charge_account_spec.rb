# encoding: utf-8

require 'spec_helper'

describe Charging::ChargeAccount, :vcr do
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
  let(:domain) do
    Factory.create_resource(Charging::Domain, current_account, Factory.domain_attributes(Faker.cnpj_generator)) 
  end

  context 'for new instance' do
    CA_ATTRIBUTES = [
      :bank, :name, :agreement_code, :portfolio_code, :account, :agency,
      :currency, :supplier_name, :address, :sequence_numbers, :advance_days
    ]
    
    let(:response) { double(:response, code: 500) }
    
    before do
      VCR.use_cassette('ChargeAccount/for new instance') do
        attributes = Hash[*CA_ATTRIBUTES.map {|attr| [attr, "#{attr} value"] }.flatten]
      
        @domain = domain
        @new_charge_account = described_class.new(attributes, domain, response)
      end
    end
    
    subject { @new_charge_account }
    
    CA_ATTRIBUTES.each do |attribute|
      its(attribute) { should eq "#{attribute} value"}
    end
    
    [:uuid, :uri, :etag, :national_identifier].each do |attribute|
      its(attribute) { should be_nil }
    end
    
    its(:domain) { should eq @domain }
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
        city_state: nil,
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
      before do
        VCR.use_cassette('ChargeAccount/creating a charge account') do
          @domain = domain
          @created_charge_account = described_class.new(attributes, @domain).create!
        end
      end
      
      subject { @created_charge_account }

      [:uuid, :uri, :etag].each do |attribute|
        its(attribute) { should_not be_nil }
      end

      it 'should be persisted' do
        expect(subject).to be_persisted
      end
    end
  end
  
  describe '#destroy!' do
    it 'should delete charge account at API' do
      VCR.use_cassette('ChargeAccount/deleting a charge account') do
        charge_account = Factory.create_resource(described_class, domain, attributes).create!
        
        expect { charge_account.destroy! }.to_not raise_error

        expect(charge_account).to be_deleted
        expect(charge_account).to_not be_persisted
      end
    end
  end
  
  describe '#update_attribute!' do
    let!(:charge_account) do
      VCR.use_cassette('ChargeAccount/get a charge account for update attribute tests') do
        Factory.create_resource(described_class, domain, attributes).create!
      end
    end

    context 'try update a readonly attribute on charge account' do
      it 'should raise' do
        VCR.use_cassette('ChargeAccount/try update bank attribute on charge account') do
          expect(charge_account.bank).to eq '237'

          expect { charge_account.update_attribute! :bank, '341' }.to raise_error Charging::Http::LastResponseError

          expect(charge_account.bank).to eq '237'
        end
      end
    end

    it 'should delete charge account at API' do
      VCR.use_cassette('ChargeAccount/updating an attribute at charge account') do
        expect { charge_account.update_attribute! :address, '123 New Address St.' }.to_not raise_error

        expect(charge_account).to be_persisted
        expect(charge_account.address).to eq '123 New Address St.'
      end
    end
  end
  
  describe '#update_attributes!' do
    it 'should delegate to update_attribute! for each attribute' do
      VCR.use_cassette('ChargeAccount/for update attributes') do
        charge_account = described_class.new(attributes, domain)

        charge_account.should_receive(:update_attribute!).exactly(3)
        charge_account.should_receive(:reload_attributes!).once
      
        charge_account.update_attributes!(address: 'New Address', zipcode: '12345', city: 'City')
      end
    end
  end

  describe '.find_all' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'domain required']

      expect { described_class.find_all(nil) }.to raise_error(*expected_error)
    end

    context 'for an account' do
      before do
        VCR.use_cassette('ChargeAccount/list all available charge accounts') do
          @domain = domain
          @charge_account = Factory.create_resource(described_class, @domain, attributes).create!
          @find_all_result = described_class.find_all(@domain)
        end
      end
      
      subject { @find_all_result }
      
      it { should be_an_instance_of(Charging::ChargeAccount::Collection) }
      its(:size) { should_not eq 0}

      it 'should contain last response information' do
        expect(@find_all_result.last_response.code).to eq 200
      end
    end
  end
  
  describe '.find_by_uuid' do
    let(:charge_account) do
      Factory.create_resource(described_class, domain, attributes).create!
    end
  
    let(:uuid) { charge_account.uuid }
    
    it 'should require an account' do
      expected_error = [ArgumentError, 'domain required']
  
      expect { described_class.find_by_uuid(nil, '') }.to raise_error(*expected_error)
    end
  
    it 'should require an uuid' do
      VCR.use_cassette('ChargeAccount/can not find without uuid') do
        expected_error = [ArgumentError, 'uuid required']
  
        expect { described_class.find_by_uuid(domain, nil) }.to raise_error(*expected_error)
      end
    end
  
    it 'should raise for invalid uuid' do
      VCR.use_cassette('ChargeAccount/finding invalid charge account') do
        expect { described_class.find_by_uuid(domain, 'invalid-uuid') }.to raise_error Charging::Http::LastResponseError
      end
    end
  
    it 'should raise if not response to success (200)' do
      VCR.use_cassette('ChargeAccount/response not success') do
        response_mock = double('AcceptedResponse', code: 202, to_s: 'AcceptedResponse')
  
        described_class
          .should_receive(:get_charge_account)
          .and_return(response_mock)
  
        expect {
          described_class.find_by_uuid(domain, uuid)
        }.to raise_error Charging::Http::LastResponseError, 'AcceptedResponse'
      end
    end
  
    context 'for a valid uuid' do
      before do
        VCR.use_cassette('ChargeAccount/finding a charging account by uuid via domain') do
          @domain = domain
          @charge_account = charge_account
          @uuid = @charge_account.uuid
          @find_result = described_class.find_by_uuid(@domain, @uuid)
        end
      end
      
      subject { @find_result }
  
      it 'should instantiate a charge account' do
        expect(subject).to be_an_instance_of(Charging::ChargeAccount)
      end
  
      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end
  
      its(:uri) { should eq "http://sandbox.charging.financeconnect.com.br/charge-accounts/#{@uuid}/" }
      its(:domain) { should eq @domain }
    end
  end
end
