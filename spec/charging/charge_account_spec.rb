require 'spec_helper'

describe Charging::ChargeAccount, :vcr do
  let(:domain) { double(:domain, token: 'QNTGvpnYRVC4HbHibDBUIQ==') }
  let(:uuid) { '29e77bc5-0e70-444c-a922-3149e78d905b' }

  context 'for new instance' do
    ATTRIBUTES = [
      :bank, :name, :agreement_code, :portfolio_code, :account, :agency, 
      :currency, :supplier_name, :address,:sequence_numbers, :advance_days
    ]
    
    let(:response) { double(:response) }
    
    subject do
      attributes = Hash[*ATTRIBUTES.map {|attr| [attr, "#{attr} value"] }.flatten]
      
      described_class.new(attributes, domain, response)
    end
    
    ATTRIBUTES.each do |attribute|
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
        name: "name value",
        portfolio_code: "portfolio_code value",
        sequence_numbers: "sequence_numbers value",
        supplier_name: "supplier_name value"
      })
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

      xit 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      # its(:uri) { should eq "http://sandbox.charging.financeconnect.com.br/account/domains/#{uuid}/" }
      # its(:uuid) { should eq uuid }
      # its(:etag) { should eq '7145f1a617cb7a7a0089035d9f3a6db6aa56f8ee' }
      # its(:national_identify) { should eq '/VWsCyHHRrOF+pKv0Pbyfg==' }
      # its(:domain) { should eq domain }
    end
  end
end
