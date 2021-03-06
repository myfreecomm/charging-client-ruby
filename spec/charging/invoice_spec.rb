# encoding: utf-8

require 'spec_helper'

describe Charging::Invoice, :vcr do
  let(:national_identifier) { Faker.cnpj_generator }
  let(:domain) { create_domain(current_account, national_identifier) }
  let(:charge_account) { create_charge_account(domain) }
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
  let(:invoice) { described_class.new(attributes, domain, charge_account).create! }

  context 'for new instance' do
    INVOICE_ATTRIBUTES = [ 
      :kind, :amount, :document_number, :drawee, :due_date, :portfolio_code,
      :charging_features, :supplier_name, :discount, :interest, :rebate,
      :ticket, :protest_code, :protest_days, :instructions, :demonstrative,
      :our_number
    ]

    let(:response) { double(:response, code: 500) }

    before do
      VCR.use_cassette('Invoice/for new instance') do
        attributes = Hash[*INVOICE_ATTRIBUTES.map {|attr| [attr, "#{attr} value"] }.flatten]
        @domain = domain
        @charge_account = charge_account

        @new_invoice = described_class.new(attributes, @domain, @charge_account, response)
      end
    end
    
    subject { @new_invoice }

    INVOICE_ATTRIBUTES.each do |attribute|
      describe attribute do
        subject { super().send(attribute) }
        it { is_expected.to eq "#{attribute} value"}
      end
    end

    [:uuid, :uri, :etag, :document_date, :paid].each do |attribute|
      describe attribute do
        subject { super().send(attribute) }
        it { is_expected.to be_nil }
      end
    end

    describe '#domain' do
      subject { super().domain }
      it { is_expected.to eq @domain }
    end

    describe '#charge_account' do
      subject { super().charge_account }
      it { is_expected.to eq @charge_account }
    end

    describe '#last_response' do
      subject { super().last_response }
      it { is_expected.to eq response }
    end

    describe '#errors' do
      subject { super().errors }
      it { is_expected.to eq [] }
    end

    specify('#persisted?') { expect(subject).to_not be_persisted }
    specify('#deleted?') { expect(subject).to_not be_deleted }

    describe '#attributes' do
      subject { super().attributes }
      it do
      is_expected.to eq({
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
        our_number: 'our_number value',
        portfolio_code: 'portfolio_code value'
      })
    end
    end
  end

  describe '#create!' do
    it 'should require a domain and load errors' do
      VCR.use_cassette('Invoice/try create an invoice with invalid domain') do
        invoice = described_class.new(attributes, nil, charge_account)

        expect(invoice.errors).to be_empty

        expected_error = [StandardError, 'can not create without a domain']
        expect { invoice.create! }.to raise_error(*expected_error)

        expect(invoice.errors).to eq ['can not create without a domain']
      end
    end

    it 'should require a charge account and load errors' do
      VCR.use_cassette('Invoice/try create an invoice with invalid charge account') do
        invoice = described_class.new(attributes, domain, nil)

        expect(invoice.errors).to be_empty

        expected_error = [StandardError, 'can not create wihtout a charge account']
        expect { invoice.create! }.to raise_error(*expected_error)

        expect(invoice.errors).to eq ['can not create wihtout a charge account']
      end
    end

    context 'when everything is OK' do
      before do
        VCR.use_cassette('Invoice/creating an invoice') do
          @charge_account = charge_account
          @domain = @charge_account.domain
          
          @invoice = described_class.new(attributes, domain, charge_account).create!
        end
      end
      
      subject { @invoice }

      [:uuid, :uri, :etag].each do |attribute|
        describe attribute do
          subject { super().send(attribute) }
          it { is_expected.not_to be_nil }
        end
      end

      it 'should be persisted' do
        expect(subject).to be_persisted
      end
    end
  end

  describe '#billet_url' do
    context 'for not persisted invoice' do
      subject {
        VCR.use_cassette('Invoice/check billet url for new invoice instance') do
          described_class.new({}, domain, charge_account, nil)
        end
      }
      
      describe '#billet_url' do
        subject { super().billet_url }
        it { is_expected.to be_nil }
      end
    end
    
    context 'for a persisted invoice' do
      it 'should be nil if something wrong' do
        VCR.use_cassette('Invoice/try get billet url when something is wrong') do
          @invoice = invoice
          
          expect(Charging::Http)
            .to receive(:get).with("/invoices/#{@invoice.uuid}/billet/", domain.token)
            .and_return(double(:server_error, code: 500, body: 'generic error message'))

          expect(@invoice.billet_url).to be_nil
        end
      end
      
      it 'should get current billet url' do
        VCR.use_cassette('Invoice/finding current billet url for invoice') do
          @invoice = invoice
          expected_url = %r{http://sandbox.charging.financeconnect.com.br/billets/#{@invoice.uuid}/\w+/}
          expect(@invoice.billet_url).to match expected_url
        end
      end
    end
  end
  
  describe '#pay!' do
    context 'when something went wrong' do
      it 'should load raise error' do
        VCR.use_cassette('Invoice/paying an invoice and something is wrong') do
          body = MultiJson.encode({
            amount: invoice.amount,
            date: Time.now.strftime('%Y-%m-%d')
          })
        
          expect(Charging::Http)
            .to receive(:post).with("/invoices/#{invoice.uuid}/pay/", domain.token, body, etag: invoice.etag)
            .and_return(double(:response, code: 500))

          expected_error = [Charging::Http::LastResponseError]
        
          expect { invoice.pay! }.to raise_error(*expected_error)
        end
      end
    end
    
    context 'when success payment' do
      it 'should update paid value' do
        VCR.use_cassette('Invoice/paying an invoice') do
          invoice.pay!
      
          expect(invoice.paid).to eq("123.45")
        end
      end
    end
    
    it 'should pass a new amount' do
      VCR.use_cassette('Invoice/paying an invoice with another amount') do
        body = MultiJson.encode({
          amount: 100,
          date: Time.now.strftime('%Y-%m-%d')
        })
        
        @invoice = invoice
        @domain = domain
      
        expect(Charging::Http)
          .to receive(:post)
          .with("/invoices/#{@invoice.uuid}/pay/", @domain.token, body, etag: @invoice.etag)
          .and_return(double(:response, code: 201))
      
        expect(invoice).to receive(:reload_attributes!)
      
        invoice.pay!(amount: 100)
      end
    end
    
    it 'should pass a payment date' do
      VCR.use_cassette('Invoice/paying an invoice with another date') do
        today = Time.now.strftime('%Y-%m-%d')
        
        @invoice = invoice
        @domain = domain
      
        body = MultiJson.encode({
          amount: @invoice.amount,
          date: today
        })
      
        expect(Charging::Http)
          .to receive(:post).with("/invoices/#{@invoice.uuid}/pay/", @domain.token, body, etag: @invoice.etag)
          .and_return(double(:response, code: 201))
      
        expect(invoice).to receive(:reload_attributes!)
      
        invoice.pay!(date: today)
      end
    end
    
    it 'should pass a note' do
      VCR.use_cassette('Invoice/paying an invoice and adding a note') do
        @invoice = invoice
        
        body = MultiJson.encode({
          amount: @invoice.amount,
          date: Time.now.strftime('%Y-%m-%d'),
          note: 'some note for payment'
        })
      
        expect(Charging::Http)
          .to receive(:post).with("/invoices/#{@invoice.uuid}/pay/", domain.token, body, etag: @invoice.etag)
          .and_return(double(:response, code: 201))
      
        expect(invoice).to receive(:reload_attributes!)
      
        invoice.pay!(note: "some note for payment")
      end
    end
  end
  
  describe '#payments' do
    context 'invoice without payments' do
      it 'should return an empty array' do
        VCR.use_cassette('Invoice/invoice without payments') do
          expect(invoice.payments).to eq []
        end
      end
    end
    
    context 'invoice with payments' do
      it 'should return an empty array' do
        VCR.use_cassette('Invoice/invoice with payments') do
          invoice.pay!
          
          expect(invoice.payments).to_not be_empty
        end
      end
    end
  end
  
  describe '#destroy!' do
    it 'should raise delete an invoice at API' do
      VCR.use_cassette('Invoice/try delete an invoice with payments') do
        invoice.pay!
        
        expect(invoice.payments).to_not be_empty
        
        expect { invoice.destroy! }.to raise_error Charging::Http::LastResponseError
        
        expect(invoice).to_not be_deleted
        expect(invoice).to be_persisted
      end
    end

    it 'should delete an invoice without payments' do
      VCR.use_cassette('Invoice/deleting an invoice without payments') do
        expect(invoice).to be_persisted
        
        expect { invoice.destroy! }.to_not raise_error
        
        expect(invoice).to be_deleted
        expect(invoice).to_not be_persisted
      end
    end
  end

  describe '.find_by_uuid' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'domain required']

      expect { described_class.find_by_uuid(nil, '') }.to raise_error(*expected_error)
    end

    it 'should require an uuid' do
      VCR.use_cassette('Invoice/try find by uuid an invoice with nil value') do
        expected_error = [ArgumentError, 'uuid required']

        expect { described_class.find_by_uuid(domain, nil) }.to raise_error(*expected_error)
      end
    end

    it 'should raise for invalid uuid' do
      VCR.use_cassette('Invoice/try find by uuid an invoice with invalid uuid') do
        expect { described_class.find_by_uuid(domain, 'invalid-uuid') }.to raise_error Charging::Http::LastResponseError
      end
    end

    it 'should raise if not response to success (200)' do
      VCR.use_cassette('Invoice/try find by uuid an invoice when response not success') do
        response_mock = double('AcceptedResponse', code: 202, to_s: 'AcceptedResponse')

        expect(described_class)
          .to receive(:get_invoice)
          .with(domain, 'uuid')
          .and_return(response_mock)

        expect {
          described_class.find_by_uuid(domain, 'uuid')
        }.to raise_error Charging::Http::LastResponseError, 'AcceptedResponse'
      end
    end

    context 'for a valid uuid' do
      before do
        VCR.use_cassette('Invoice/find by uuid an invoice') do
          @invoice = invoice
          @find_result = described_class.find_by_uuid(domain, @invoice.uuid)
        end
      end
      
      subject { @find_result }

      it 'should instantiate a charge account' do
        expect(subject).to be_an_instance_of(Charging::Invoice)
      end

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq "http://sandbox.charging.financeconnect.com.br/invoices/#{@invoice.uuid}/" }
      end
    end
  end

  describe '.kinds' do
    it 'should require a domain' do
      expected_error = [ArgumentError, 'domain required']
      
      expect { described_class.kinds(nil) }.to raise_error(*expected_error)
    end
    
    it 'should raise for invalid domain' do
      VCR.use_cassette('Invoice/try get invoice kinds with invalid domain token') do
        expected_error = [Charging::Http::LastResponseError]
        
        expect { described_class.kinds(double(token: 'invalid')) }.to raise_error(*expected_error)
      end
    end
    
    it 'should return an array with first page' do
      VCR.use_cassette('Invoice/get first page of invoice kinds') do
        default_result = described_class.kinds(domain)
        first_page_result = described_class.kinds(domain, 1)
        
        expect(default_result).to eq first_page_result
        
        expect(default_result).to include({"acronym"=>"DM", "itau_code"=>1, "code"=>2, "name"=>"Duplicata Mercantil"})
        expect(default_result.size).to eq 10
      end
    end
    
    it 'should return an array with second page' do
      VCR.use_cassette('Invoice/get second page of invoice kinds') do
        result = described_class.kinds(domain, 2)
                
        expect(result).to_not include({"acronym"=>"DM", "itau_code"=>1, "code"=>2, "name"=>"Duplicata Mercantil"})
        expect(result.size).to eq 10
      end
    end
    
    it 'should return an array of kinds passing new limit per page' do
      VCR.use_cassette('Invoice/get first page of invoice kinds with 12 items per page') do
        result = described_class.kinds(domain, 1, 12)
        
        expect(result).to include({"acronym"=>"DM", "itau_code"=>1, "code"=>2, "name"=>"Duplicata Mercantil"})
        expect(result.size).to eq 12
      end
    end
  end
end
