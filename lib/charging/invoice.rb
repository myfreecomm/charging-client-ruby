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

      reload_attributes_after_create!
    rescue ::RestClient::Exception => exception
      @last_response = exception.response

      raise Http::LastResponseError.new(last_response)
    ensure
      @errors = [$ERROR_INFO.message] if $ERROR_INFO
    end
    
    def self.load_persisted_invoice(attributes, response, domain, charge_account)
      attributes.delete("charge_account")
      validate_attributes!(attributes)
      
      Invoice.new(attributes, domain, charge_account, response)
    end

    private

    def reload_attributes_after_create!
      response = Http.get(last_response.headers[:location], domain.token)

      new_invoice = Invoice.load_persisted_invoice(MultiJson.decode(response.body), response, domain, charge_account)

      (COMMON_ATTRIBUTES + READ_ONLY_ATTRIBUTES).each do |attribute|
        instance_variable_set "@#{attribute}", new_invoice.send(attribute)
      end

      self
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