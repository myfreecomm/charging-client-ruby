# encoding: UTF-8

module Charging
  class ChargeAccount < Base

    READ_ONLY_ATTRIBUTES = [:national_identifier]
    
    ATTRIBUTES = [
      :account, :agency, :name, :portfolio_code, :address, :sequence_numbers,
      :currency, :agreement_code, :supplier_name, :advance_days, :bank
    ]

    attr_accessor(*ATTRIBUTES)
    attr_reader(*READ_ONLY_ATTRIBUTES)
    attr_reader :domain
    
    def initialize(attributes, domain, response = nil)
      super(attributes, response)
      @domain = domain
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
    
    # Represents a charge account collection result for <tt>ChargeAccount.find_all</tt>. It is
    # a delegator for an array of Domain.
    class Collection < SimpleDelegator

      # Responds the last http response from the API.
      attr_reader :last_response

      # Responds the current Domain instance.
      attr_reader :domain

      def initialize(domain, response) # :nodoc:
        Helpers.required_arguments!(domain: domain, response: response)

        @domain = domain
        @last_response = response
        super(load_data_with_response!)
      end

      def load_data_with_response! # :nodoc:
        return [] if last_response.code != 200

        raw_domains = MultiJson.decode(last_response.body)
        raw_domains.map { |raw_domain| load_charge_account(domain, raw_domain) }
      end

      def load_charge_account(domain, attributes) # :nodoc:
        ChargeAccount.load_persisted_charge_account(attributes, last_response, domain)
      end
    end
  end
end