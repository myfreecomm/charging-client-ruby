# encoding: utf-8

module Charging
  class Domain
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

    ATTRIBUTES = [ :supplier_name, :address, :city_state, :zipcode,
      :national_identifier, :description, :uuid, :etag, :uri, :token ]

    attr_accessor *ATTRIBUTES, :account
    attr_reader :last_response

    def initialize(attributes, response)
      Helpers.load_variables(self, ATTRIBUTES, attributes)

      @last_response = response
    end

    def persisted?
      !!(uuid && etag && uri && token)
    end

    def self.find_all(account, page = DEFAULT_PAGE, limit = DEFAULT_LIMIT)
      Helpers.required_arguments!('service account' => account)

      response = get_account_domains(account, page, limit)

      DomainCollection.new(account, response)
    end

    def self.find_by_uuid(account, uuid)
      Helpers.required_arguments!('service account' => account, uuid: uuid)

      response = get_account_domain(account, uuid)

      raise Http::LastResponseError.new(response) if response.code != 200

      load_persisted_domain(MultiJson.decode(response.body), response, account)
    rescue ::RestClient::Exception => exception
      raise Http::LastResponseError.new(exception.response)
    end

    def self.find_by_token(token)
      Helpers.required_arguments!('token' => token)

      response = get_domain(token)

      raise Http::LastResponseError.new(response) if response.code != 200

      load_persisted_domain(MultiJson.decode(response.body), response)
    rescue ::RestClient::Exception => exception
      raise Http::LastResponseError.new(exception.response)
    end

    def self.load_persisted_domain(attributes, response, account = nil)
      validate_attributes!(attributes)
      domain = Domain.new(attributes, response)
      domain.account = account if account
      domain
    end

    private

    def self.get_domain(token)
      Http.get('/domain/', token)
    end

    def self.get_account_domain(account, uuid)
      Http.get("/account/domains/#{uuid}/", account.application_token)
    end

    def self.validate_attributes!(attributes)
      keys = attributes.keys.map(&:to_sym)
      diff = keys - ATTRIBUTES
      raise ArgumentError, "Invalid attributes for domain: #{attributes.inspect}" if diff.any?
    end

    def self.get_account_domains(account, page, limit)
      Http.get("/account/domains/?page=#{page}&limit=#{limit}", account.application_token)
    end

    def self.create_domain_collection_for(response)
      data = response.code === 200 ? MultiJson.decode(response.body) : []

      DomainCollection.new(data, response)
    end
  end

  class DomainCollection < SimpleDelegator
    attr_reader :last_response, :account

    def initialize(account, response)
      Helpers.required_arguments!('service account' => account, 'response' => response)

      @account = account
      @last_response = response
      super(load_data_with_response!)
    end

    def load_data_with_response!
      return [] if last_response.code != 200

      raw_domains = MultiJson.decode(last_response.body)
      raw_domains.map { |raw_domain| load_domain(account, raw_domain) }
    end

    def load_domain(account, attributes)
      Domain.load_persisted_domain(attributes, last_response, account)
    end
  end
end
