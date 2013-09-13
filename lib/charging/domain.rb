# encoding: utf-8

module Charging
  class Domain
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

    ATTRIBUTES = [ :supplier_name, :address, :city_state, :zipcode,
      :national_identifier, :description, :uuid, :etag ]

    attr_accessor *ATTRIBUTES, :account
    attr_reader :last_response

    def initialize(attributes, response)
      Helpers.load_variables(self, ATTRIBUTES, attributes)

      @last_response = response
    end

    def persisted?
      !!(uuid && etag)
    end

    def self.find_all(account, page = DEFAULT_PAGE, limit = DEFAULT_LIMIT)
      Helpers.required_arguments!('service account' => account)

      response = get_account_domains(account, page, limit)
      DomainCollection.new(account, response)
    end

    def self.load_persisted_domain(attributes, response)
      Domain.new(attributes, response)
    end

    private

    def self.get_account_domains(account, page, limit)
      Http.get("/account/domains/?page=#{page}&limit=#{limit}", account.application_token)
    end

    def self.create_domiain_collection_for(response)
      data = response.code === 200 ? MultiJson.decode(response.body) : []

      DomainCollection.new(data, response)
    end
  end

  class DomainCollection
    extend Forwardable

    def_delegators :@data, :size, :each, :first, :last, :each_with_index, :[]

    attr_reader :last_response, :account

    def initialize(account, response)
      Helpers.required_arguments!('service account' => account)

      @account = account
      @last_response = response
      @data = load_data_with_response!
    end

    def load_data_with_response!
      return [] if last_response.code != 200

      raw_domains = MultiJson.decode(last_response.body)
      raw_domains.map { |raw_domain| load_domain(account, raw_domain) }
    end

    def load_domain(account, attributes)
      Domain.load_persisted_domain(attributes, last_response)
    end
  end
end
