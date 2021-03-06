# encoding: utf-8

module Charging
  # Represents a Charging service account.
  class ServiceAccount
    ATTRIBUTES = [:plan, :name, :uri, :uuid]

    attr_accessor(*ATTRIBUTES)

    # Responds the last http response from the API.
    attr_reader :last_response

    # Responds the current application token
    attr_reader :application_token
    
    def self.current
      @current ||= find_by_token(Charging.configuration.application_token)
    end

    # Initializes a service account instance, to represent a charging account
    def initialize(attributes, response, token) # :nodoc:
      Helpers.load_variables(self, ATTRIBUTES, attributes)

      @last_response = response
      @application_token = token
    end

    # Finds a service account by it's access token. Returns the service account
    # instance with all fields set if successful. If something went wrong, it
    # raises Charging::Http::LastResponseError.
    #
    # API documentation: http://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-account-entry-point
    def self.find_by_token(token)
      response = Http.get('/account/', token)

      raise Http::LastResponseError.new(response) if response.code != 200

      self.load_service_account_for response, token
    rescue ::RestClient::Exception => exception
      raise Http::LastResponseError.new(exception.response)
    end

    private

    def self.load_service_account_for(response, token)
      data = MultiJson.decode(response.body)
      self.new(data, response, token)
    end
  end
end
