# encoding: UTF-8

module Charging
  class ChargeAccount
    READ_ONLY_ATTRIBUTES = [:uuid, :uri, :etag, :national_indentify]
    ATTRIBUTES = [
      :bank, :name, :agreement_code, :portfolio_code, :account, :agency, 
      :default_charging_features, :currency, :supplier_name, :address, 
      :zipcode, :sequence_number, :our_number_range, :advance_days
    ]
    
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
      !!(uuid && etag && uri && national_indentify && !deleted?)
    end

    # Returns true if domains already deleted on API
    def deleted?
      !!@deleted
    end

    # Returns a hash with attributes
    def attributes
      Helpers.hashify(self, ATTRIBUTES)
    end
  end
end