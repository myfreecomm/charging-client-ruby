# encoding: utf-8

module Charging
  # Represents a Charging service account.
  class ServiceAccount
    ATTRIBUTES = [:plan, :name, :uri, :uuid]

    attr_accessor *ATTRIBUTES

    # Responds the last http response of the API.
    attr_reader :last_response, :application_token

    # Finds a service account by it's access token. Returns the service account
    # instance with all fields set if successful. If something went wrong, it
    # raises Charging::Http::LastResponseError.
    #
    # API documentation: http://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-account-entry-point
    def self.find(token)
      response = ::Charging::Http.get('/account/', token)

      raise Http::LastResponseError.new(response) if response.code != 200

      self.load_service_account_for response, token
    rescue RestClient::Exception => exception
      raise Http::LastResponseError.new(exception.response)
    end

    def initialize(attributes, response, token) # :nodoc:
      attributes.each do |attr, value|
        instance_variable_set("@#{attr}", value)
      end

      @last_response = response
      @application_token = token
    end

    private

    def self.load_service_account_for(response, token)
      data = MultiJson.decode(response.body)
      self.new(data, response, token)
    end

    def attributes
      ATTRIBUTES.inject({}) do |hash, attribute|
        hash[attribute] = send(attribute)
        hash
      end
    end
  end
end
