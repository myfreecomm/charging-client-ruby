# encoding: utf-8

require 'spec_helper'

describe Charging::Invoice, :vcr do
  let(:charge_account) { double(:charge_account, uuid: '29e77bc5-0e70-444c-a922-3149e78d905b') }
  let(:domain) { double(:domain, token: 'QNTGvpnYRVC4HbHibDBUIQ==') }
  let(:attributes) do
    {
      kind: 2,
      amount: 123.45,
      document_number: '000000000000001',
      drawee: {
        name: 'Nome do Sacado',
        address: 'Rua do Carmo, 43',
        city_state: 'Rio de Janeiro/RJ',
        zipcode: '21345-999',
        national_identifier: '37.818.380/0001-86'
      },
      due_date: '2020-12-31'
    }
  end
  let(:uuid) { '6a6084a3-a0c0-42ab-94f8-d5e8c4b94d7f' }

  context 'for new instance' do
    INVOICE_ATTRIBUTES = [ 
      :kind, :amount, :document_number, :drawee, :due_date, 
      :charging_features, :supplier_name, :discount, :interest, :rebate,
      :ticket, :protest_code, :protest_days, :instructions, :demonstrative,
      :our_number
    ]

    let(:response) { double(:response, code: 500) }

    subject do
      attributes = Hash[*INVOICE_ATTRIBUTES.map {|attr| [attr, "#{attr} value"] }.flatten]

      described_class.new(attributes, domain, charge_account, response)
    end

    INVOICE_ATTRIBUTES.each do |attribute|
      its(attribute) { should eq "#{attribute} value"}
    end

    [:uuid, :uri, :etag, :document_date, :paid].each do |attribute|
      its(attribute) { should be_nil }
    end

    its(:domain) { should eq domain }
    its(:charge_account) { should eq charge_account }
    its(:last_response) { should eq response }
    its(:errors) { should eq [] }

    specify('#persisted?') { expect(subject).to_not be_persisted }
    specify('#deleted?') { expect(subject).to_not be_deleted }

    its(:attributes) do
      should eq({
        amount: 'amount value',
        kind: 'kind value',
        document_number: 'document_number value',
        drawee: 'drawee value',
        due_date: 'due_date value',
        charging_features: 'charging_features value',
        supplier_name: 'supplier_name value', 
        discount: 'discount value', 
        interest: 'interest value', 
        rebate: 'rebate value', 
        ticket: 'ticket value', 
        protest_code: 'protest_code value', 
        protest_days: 'protest_days value', 
        instructions: 'instructions value', 
        demonstrative: 'demonstrative value', 
        our_number: 'our_number value'
      })
    end
  end

  describe '#create!' do
    it 'should require a domain and load errors' do
      invoice = described_class.new(attributes, nil, charge_account)

      expect(invoice.errors).to be_empty

      expected_error = [StandardError, 'can not create without a domain']
      expect { invoice.create! }.to raise_error(*expected_error)

      expect(invoice.errors).to eq ['can not create without a domain']
    end

    it 'should require a charge account and load errors' do
      invoice = described_class.new(attributes, domain, nil)

      expect(invoice.errors).to be_empty

      expected_error = [StandardError, 'can not create wihtout a charge account']
      expect { invoice.create! }.to raise_error(*expected_error)

      expect(invoice.errors).to eq ['can not create wihtout a charge account']
    end

    context 'when everything is OK' do
      subject { described_class.new(attributes, domain, charge_account) }

      before do
        VCR.use_cassette('creating an invoice') do
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
      VCR.use_cassette('finding invoice with invalid uuid') do
        expect { described_class.find_by_uuid(domain, 'invalid-uuid') }.to raise_error Charging::Http::LastResponseError
      end
    end

    it 'should raise if not response to success (200)' do
      response_mock = double('AcceptedResponse', code: 202, to_s: 'AcceptedResponse')

      described_class
        .should_receive(:get_invoice)
        .with(domain, uuid)
        .and_return(response_mock)

      expect {
        described_class.find_by_uuid(domain, uuid)
      }.to raise_error Charging::Http::LastResponseError, 'AcceptedResponse'
    end

    context 'for a valid uuid' do
      subject do
        VCR.use_cassette('finding an invoice by uuid') do
          described_class.find_by_uuid(domain, uuid)
        end
      end

      it 'should instantiate a charge account' do
        expect(subject).to be_an_instance_of(Charging::Invoice)
      end

      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      its(:uri) { should eq "http://sandbox.charging.financeconnect.com.br/invoices/#{uuid}/" }
      its(:uuid) { should eq uuid }
      its(:etag) { should eq '"75de28a49a515edef88b3285921808a3d86ea5bf"' }
      its(:domain) { should eq domain }
    end
  end
end
