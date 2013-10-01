# encoding: utf-8

module Charging
  class Invoice < Base
    ATTRIBUTES = [
      :kind, :amount, :document_number, :drawee, :due_date, 
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
      @errors = []
      raise 'can not create without a domain' if invalid_domain?
      raise 'can not create wihtout a charge account' if invalid_charge_account?

      @last_response = Invoice.post_charge_accounts_invoices(domain, charge_account, attributes)

      raise Http::LastResponseError.new(last_response) if last_response.code != 201

      reload_attributes!(last_response.headers[:location])
    rescue ::RestClient::Exception => exception
      @last_response = exception.response

      raise Http::LastResponseError.new(last_response)
    ensure
      @errors = [$ERROR_INFO.message] if $ERROR_INFO
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
      attributes = {
        amount: self.amount,
        date: Time.now.strftime('%Y-%m-%d')
      }.merge(payment_data)
      
      response = Http.post("/invoices/#{uuid}/pay/", domain.token, MultiJson.encode(attributes), etag: self.etag)
      
      raise Http::LastResponseError.new(response) if response.code != 201
      
      reload_attributes!(self.uri)
    rescue ::RestClient::Exception => excetion
      raise Http::LastResponseError.new(excetion.response)
    end
    
    # Deletes the invoice at API
    # 
    # API method: <tt>DELETE /invoices/:uuid/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#delete-invoices-uuid
    def destroy!
      response = Http.delete("/invoices/#{uuid}/", domain.token, etag)
      
      raise Http::LastResponseError.new(response) if response.code != 204
      
      @deleted = true
      @persisted = false
    rescue RestClient::Exception => excetion
      raise Http::LastResponseError.new(excetion.response)
    end
    
    # List all payments for an invoice
    #
    # API method: <tt>GET /invoices/:uuid/payments/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#get-invoices-uuid-payments
    def payments
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
      
      raise Http::LastResponseError.new(response) if response.code != 200
      
      load_persisted_invoice(MultiJson.decode(response.body), response, domain)
    rescue ::RestClient::Exception => excetion
      raise Http::LastResponseError.new(excetion.response)
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

    def reload_attributes!(uri)
      response = Http.get(uri, domain.token)

      new_invoice = Invoice.load_persisted_invoice(MultiJson.decode(response.body), response, domain, charge_account)

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
