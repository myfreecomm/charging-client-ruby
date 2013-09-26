# encoding: UTF-8

module Charging
  class ChargeAccount < Base
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

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
    
    def self.load_persisted_charge_account(attributes, response, domain)
      validate_attributes!(attributes)
      ChargeAccount.new(attributes, domain, response)
    end
    
    private
    
    def self.get_charge_accounts(domain, page, limit)
      Http.get("/charge-accounts/?page=#{page}&limit=#{limit}", domain.token)
    end
    
    def self.get_charge_account(domain, uuid)
      Http.get("/charge-accounts/#{uuid}/", domain.token)
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
