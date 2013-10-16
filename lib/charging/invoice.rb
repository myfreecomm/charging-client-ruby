# encoding: utf-8

module Charging
  class Invoice < Base
    ATTRIBUTES = [
      :kind, :amount, :document_number, :drawee, :due_date, :portfolio_code,
      :charging_features, :supplier_name, :discount, :interest, :rebate,
      :ticket, :protest_code, :protest_days, :instructions, :demonstrative,
      :our_number
    ]

    READ_ONLY_ATTRIBUTES = [ :document_date, :paid ]

    attr_accessor(*ATTRIBUTES)
    attr_reader(*READ_ONLY_ATTRIBUTES, :domain, :charge_account)

    def initialize(attributes, domain, charge_account, response = nil)
      super(attributes, response)
      @domain = domain
      @charge_account = charge_account
    end

    # Creates current invoice at API.
    #
    # API method: <tt>POST /charge-accounts/:uuid/invoices/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#post-charge-accounts-uuid-invoices
    def create!
      super do
        raise 'can not create without a domain' if invalid_domain?
        raise 'can not create wihtout a charge account' if invalid_charge_account?
        
        Invoice.post_charge_accounts_invoices(domain, charge_account, attributes)
      end
      
      reload_attributes!(Helpers.extract_uuid(last_response.headers[:location]))
    end
    
    # Deletes the invoice at API
    # 
    # API method: <tt>DELETE /invoices/:uuid/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#delete-invoices-uuid
    def destroy!
      super do
        Http.delete("/invoices/#{uuid}/", domain.token, etag)
      end
    end
    
    # Pays current invoice at API. You can pass <tt>paid_amount</tt>, 
    # <tt>payment_date</tt> and <tt>note</tt> about payment. 
    # Default values:
    # - <tt>amount</tt>: amount
    # - <tt>date</tt>:  Time.now.strftime('%Y-%m-%d')
    #
    # API method: <tt>POST /invoices/:uuid/pay/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#post-invoices-uuid-pay
    def pay!(payment_data = {})
      reset_errors!
      
      attributes = {
        amount: self.amount,
        date: Time.now.strftime('%Y-%m-%d')
      }.merge(payment_data)

      @last_response = Http.post("/invoices/#{uuid}/pay/", domain.token, MultiJson.encode(attributes), etag: self.etag)
      
      raise_last_response_unless 201
      
      reload_attributes!(uuid)
    ensure
      if $ERROR_INFO
        @last_response = $ERROR_INFO.last_response if $ERROR_INFO.kind_of?(Http::LastResponseError)
        @errors = [$ERROR_INFO.message]
      end
    end
    
    # List all payments for an invoice
    #
    # API method: <tt>GET /invoices/:uuid/payments/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#get-invoices-uuid-payments
    def payments
      reset_errors!
      
      response = Http.get("/invoices/#{uuid}/payments/", domain.token)
      
      return [] if response.code != 200
      
      MultiJson.decode(response.body)
    end
    
    # Finds an invoice by uuid. It requites an <tt>domain</tt> and a
    # <tt>uuid</tt>.
    #
    # Returns an Invoice instance or raises a Http::LastResponseError if something
    # went wrong, like unauthorized request, not found.
    #
    # API method: <tt>GET /invoices/:uuid/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#get-invoices-uuid
    def self.find_by_uuid(domain, uuid)
      Helpers.required_arguments!(domain: domain, uuid: uuid)
      
      response = Invoice.get_invoice(domain, uuid)
      
      raise_last_response_unless 200, response
      
      load_persisted_invoice(MultiJson.decode(response.body), response, domain)
    end
    
    # Returns a String with the temporary URL for print current invoice.
    # 
    # API method: <tt>GET /invoices/:uuid/billet/
    # 
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#get-invoices-uuid-billet
    def billet_url
      return if unpersisted?
      
      response = Http.get("/invoices/#{uuid}/billet/", domain.token)
      
      return if response.code != 200
      
      MultiJson.decode(response.body)["billet"]
    rescue
      nil
    end

    def self.load_persisted_invoice(attributes, response, domain, charge_account = nil)
      charge_account_uri = attributes.delete("charge_account").to_s
      
      if charge_account.nil? && charge_account_uri.start_with?('http')
        begin
          charge_account = ChargeAccount.find_by_uri(domain, charge_account_uri)
        rescue Http::LastResponseError
        end
      end
      
      validate_attributes!(attributes)
      
      Invoice.new(attributes, domain, charge_account, response)
    end

    private
    
    def reload_attributes!(uuid)
      new_invoice = self.class.find_by_uuid(domain, uuid)

      (COMMON_ATTRIBUTES + READ_ONLY_ATTRIBUTES).each do |attribute|
        instance_variable_set "@#{attribute}", new_invoice.send(attribute)
      end

      self
    end
    
    def self.get_invoice(domain, uuid)
      Http.get("/invoices/#{uuid}/", domain.token)
    end
    
    def self.post_charge_accounts_invoices(domain, charge_account, attributes)
      Http.post("/charge-accounts/#{charge_account.uuid}/invoices/", domain.token, MultiJson.encode(attributes))
    end

    def invalid_domain?
      domain.nil?
    end

    def invalid_charge_account?
      charge_account.nil?
    end
  end
end
