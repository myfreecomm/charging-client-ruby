# encoding: UTF-8

module Charging
  class ChargeAccount
    READ_ONLY_ATTRIBUTES = [:etag, :uri, :national_identifier, :uuid]
    ATTRIBUTES = [
      :account, :agency, :name, :portfolio_code, :address, :sequence_numbers,
      :currency, :agreement_code, :supplier_name, :advance_days, :bank
    ]
    [:default_charging_features, :zipcode, :our_number_range]
    # READ_ONLY_ATTRIBUTES = [:uuid, :uri, :etag, :national_identify]
    # ATTRIBUTES = [
    #   :bank, :name, :agreement_code, :portfolio_code, :account, :agency, 
    #   :default_charging_features, :currency, :supplier_name, :address, 
    #   :zipcode, :sequence_number, :our_number_range, :advance_days
    # ]
    
    attr_accessor(*ATTRIBUTES)
    attr_reader(*READ_ONLY_ATTRIBUTES)
    attr_reader :last_response, :errors
    attr_reader :domain
    
    def initialize(attributes, domain, response = nil)
      Helpers.load_variables(self, ATTRIBUTES + READ_ONLY_ATTRIBUTES, attributes)

      @last_response = response
      @domain = domain
      @errors = []
      @deleted = false
    end

    # Returns true if the Charge Account exists on Charging service.
    def persisted?
      !!(uuid && etag && uri && national_identify && !deleted?)
    end

    # Returns true if domains already deleted on API
    def deleted?
      !!@deleted
    end

    # Returns a hash with attributes
    def attributes
      Helpers.hashify(self, ATTRIBUTES)
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
      
      raise Http::LastResponseError.new(response) if response.code != 200
      
      load_persisted_charge_account(MultiJson.decode(response.body), response, domain)
    rescue ::RestClient::Exception => excetion
      raise Http::LastResponseError.new(excetion.response)
    end
    
    def self.load_persisted_charge_account(attributes, response, domain)
      validate_attributes!(attributes)
      ChargeAccount.new(attributes, domain, response)
    end
    
    private
    
    def self.get_charge_account(domain, uuid)
      Http.get("/charge-accounts/#{uuid}/", domain.token)
    end
    
    def self.validate_attributes!(attributes)
      keys = attributes.keys.map(&:to_sym)
      diff = keys - (ATTRIBUTES + READ_ONLY_ATTRIBUTES)
      raise ArgumentError, "Invalid attributes for domain: #{attributes.inspect}" if diff.any?
    end
  end
end