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
      its(:etag) { should eq subject.last_response.headers[:etag] }
      its(:domain) { should eq domain }
    end
  end
  
  describe '#billet_url' do
    context 'for not persisted invoice' do
      subject {
        described_class.new({}, domain, charge_account, nil)
      }
      
      its(:billet_url) { should be_nil }
    end
    
    context 'for a persisted invoice' do
      let!(:invoice) {
        VCR.use_cassette('finding an invoice by uuid') do
          described_class.find_by_uuid(domain, uuid)
        end
      }

      it 'should be nil if something wrong' do
        Charging::Http
          .should_receive(:get).with("/invoices/#{uuid}/billet/", domain.token)
          .and_return(double(:server_error, code: 500, body: 'generic error message'))

        expect(invoice.billet_url).to be_nil
      end
      
      it 'should get current billet url' do
        VCR.use_cassette('finding current billet url for invoice') do
          expect(invoice.billet_url).to eq 'http://sandbox.charging.financeconnect.com.br/billets/6a6084a3-a0c0-42ab-94f8-d5e8c4b94d7f/ff010b11609c4ac2b78062f2cd51f22f/'
        end
      end
    end
  end
  
  describe '#pay!' do
    let!(:invoice) {
      VCR.use_cassette('finding an invoice by uuid') do
        described_class.find_by_uuid(domain, uuid)
      end
    }
    
    context 'when something went wrong' do
      it 'should update paid value' do
        body = MultiJson.encode({
          amount: invoice.amount.to_s,
          date: Time.now.strftime('%Y-%m-%d')
        })
        
        Charging::Http
          .should_receive(:post).with("/invoices/#{uuid}/pay/", domain.token, body, etag: invoice.etag)
          .and_return(double(:response, code: 500))

        expected_error = [StandardError, 'can not create without a domain']
        
        expect { invoice.pay! }.to_not raise_error(*expected_error)
      end
    end
    
    context 'when success payment' do
      it 'should update paid value' do
        VCR.use_cassette('paying an invoice') do
          invoice.pay!
        end
      
        expect(invoice.paid).to eq(invoice.amount)
      end
    end
    
    it 'should pass a new amount' do
      body = MultiJson.encode({
        amount: 100,
        date: Time.now.strftime('%Y-%m-%d')
      })
      
      Charging::Http
        .should_receive(:post).with("/invoices/#{uuid}/pay/", domain.token, body, etag: invoice.etag)
        .and_return(double(:response, code: 201))
      
      invoice.should_receive(:reload_attributes!)
      
      invoice.pay!(amount: 100)
    end
    
    it 'should pass a payment date' do
      today = Time.now.strftime('%Y-%m-%d')
      
      body = MultiJson.encode({
        amount: invoice.amount,
        date: today
      })
      
      Charging::Http
        .should_receive(:post).with("/invoices/#{uuid}/pay/", domain.token, body, etag: invoice.etag)
        .and_return(double(:response, code: 201))
      
      invoice.should_receive(:reload_attributes!)
      
      invoice.pay!(date: today)
    end
    
    it 'should pass a note' do
      body = MultiJson.encode({
        amount: invoice.amount,
        date: Time.now.strftime('%Y-%m-%d'),
        note: 'some note for payment'
      })
      
      Charging::Http
        .should_receive(:post).with("/invoices/#{uuid}/pay/", domain.token, body, etag: invoice.etag)
        .and_return(double(:response, code: 201))
      
      invoice.should_receive(:reload_attributes!)
      
      invoice.pay!(note: "some note for payment")
    end
  end
  
  describe '#payments' do
    let!(:invoice) {
      VCR.use_cassette('finding an invoice by uuid') do
        described_class.find_by_uuid(domain, uuid)
      end
    }
    
    context 'invoice without payments' do
      it 'should return an empty array' do
        VCR.use_cassette('invoice without payments') do
          expect(invoice.payments).to eq []
        end
      end
    end
    
    context 'invoice with payments' do
      it 'should return an empty array' do
        VCR.use_cassette('invoice with payments') do
          expect(invoice.payments).to_not be_empty
        end
      end
    end
  end
  
  describe '#destroy!' do
    it 'should raise delete an invoice at API' do
      VCR.use_cassette('try delete an invoice with payments') do
        invoice = described_class.find_by_uuid(domain, uuid)
        
        expect { invoice.destroy! }.to raise_error Charging::Http::LastResponseError
        
        expect(invoice).to_not be_deleted
        expect(invoice).to be_persisted
      end
    end

    it 'should delete an invoice at API' do
      VCR.use_cassette('deleting an invoice') do
        invoice = described_class.new(attributes, domain, charge_account)
        expect { invoice.create! }.to_not raise_error
        expect(invoice).to be_persisted
        
        expect { invoice.destroy! }.to_not raise_error
        
        expect(invoice).to be_deleted
        expect(invoice).to_not be_persisted
      end
    end
  end
end
