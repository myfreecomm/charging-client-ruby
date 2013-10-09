# encoding: UTF-8

module Charging
  class ChargeAccount < Base
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

    READ_ONLY_ATTRIBUTES = [:national_identifier]
    
    ATTRIBUTES = [
      :account, :agency, :name, :portfolio_code, :address, :zipcode, 
      :sequence_numbers, :currency, :agreement_code, :supplier_name, 
      :advance_days, :bank, :our_number_range, :default_charging_features
    ]

    attr_accessor(*ATTRIBUTES)
    attr_reader(*READ_ONLY_ATTRIBUTES, :domain)
    
    def initialize(attributes, domain, response = nil)
      super(attributes, response)
      @domain = domain
    end

    # Creates current charge account at API.
    #
    # API method: <tt>POST /account/domains/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#post-account-domains
    def create!
      super do
        raise 'can not create without a domain' if invalid_domain?

        ChargeAccount.post_charge_accounts(domain, attributes)
      end

      reload_attributes!
    end

    # Deletes the charge account at API
    # 
    # API method: <tt>DELETE /charge-accounts/:uuid/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#delete-charge-accounts-uuid
    def destroy!
      super do
        Http.delete("/charge-accounts/#{uuid}/", domain.token, etag)
      end
    end
    
    # Update an attribute on charge account at API
    # 
    # API method: <tt>PATCH /charge-accounts/:uuid/</tt>
    # 
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#patch-charge-accounts-uuid
    def update_attribute!(attribute, value)
      execute_and_capture_raises_at_errors(204) do
        @last_response = Http.patch("/charge-accounts/#{uuid}/", domain.token, etag, attribute => value)
      end
      
      reload_attributes!
    end
    
    # Finds a charge account by uuid. It requites an <tt>domain</tt> and a
    # <tt>uuid</tt>.
    #
    # Returns a ChargeAccount instance or raises a Http::LastResponseError if something
    # went wrong, like unauthorized request, not found.
    #
    # API method: <tt>GET /charge-accounts/:uuid/</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#get-charge-accounts-uuid
    def self.find_by_uuid(domain, uuid)
      Helpers.required_arguments!(domain: domain, uuid: uuid)
      
      response = ChargeAccount.get_charge_account(domain, uuid)
      
      raise_last_response_unless 200, response
      
      load_persisted_charge_account(MultiJson.decode(response.body), response, domain)
    end
    
    # Finds all charge accounts for a domain. It requites an <tt>domain</tt>,
    # and you should pass <tt>page</tt> and/or <tt>limit</tt> to apply on find.
    #
    # Returns a Collection (Array-like) of ChargeAccount
    #
    # API method: <tt>GET /charge-accounts/?page=:page&limit=:limit</tt>
    #
    # API documentation: https://charging.financeconnect.com.br/static/docs/charges.html#get-charge-accounts-limit-limit-page-page
    def self.find_all(domain, page = DEFAULT_PAGE, limit = DEFAULT_LIMIT)
      Helpers.required_arguments!(domain: domain)

      response = get_charge_accounts(domain, page, limit)

      Collection.new(domain, response)
    end
    
    # Finds a charge account by uri. It requites an <tt>domain</tt> and a
    # <tt>String</tt>.
    #
    # Returns a ChargeAccount instance or raises a Http::LastResponseError if something
    # went wrong, like unauthorized request, not found.
    def self.find_by_uri(domain, uri)
      Helpers.required_arguments!(domain: domain, uri: uri)
      
      response = Http.get(uri, domain.token)
      
      raise_last_response_unless 200, response
      
      ChargeAccount.load_persisted_charge_account(MultiJson.decode(response.body), response, domain)
    end
    
    def self.load_persisted_charge_account(attributes, response, domain)
      validate_attributes!(attributes)
      ChargeAccount.new(attributes, domain, response)
    end
    
    private
    
    def invalid_domain?
      domain.nil?
    end
    
    def reload_attributes!
      new_charge_account = ChargeAccount.find_by_uri(domain, last_response.headers[:location])
      
      (ATTRIBUTES + COMMON_ATTRIBUTES + READ_ONLY_ATTRIBUTES).each do |attribute|
        instance_variable_set "@#{attribute}", new_charge_account.send(attribute)
      end

      self
    end
    
    def self.get_charge_accounts(domain, page, limit)
      Http.get("/charge-accounts/?page=#{page}&limit=#{limit}", domain.token)
    end
    
    def self.get_charge_account(domain, uuid)
      Http.get("/charge-accounts/#{uuid}/", domain.token)
    end
    
    def self.post_charge_accounts(domain, attributes)
      Http.post('/charge-accounts/', domain.token, MultiJson.encode(attributes))
    end
    
    class Collection < Charging::Collection
      def initialize(domain, response)
        super(response, domain: domain)
      end
      
      def load_object_with(attributes)
        ChargeAccount.load_persisted_charge_account(attributes, last_response, @domain)
      end
    end
  end
end
