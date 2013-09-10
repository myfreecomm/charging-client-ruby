# encoding: utf-8

module Charging
  class NullServiceAccount < NullObject; end # :nodoc:

  # Represents a Charging service account.
  class ServiceAccount
    ATTRIBUTES = [:plan, :name, :uri, :uuid]

    attr_accessor *ATTRIBUTES

    # Responds the last http response of the API.
    attr_reader :last_response

    # Finds a service account by it's access token. Returns the service account
    # instance with all fields set if successful. Returns a NullServiceAccount
    # instance if something went wrong.
    #
    # API documentation: http://charging.financeconnect.com.br/static/docs/accounts_and_domains.html#get-account-entry-point
    def self.find(token)
      response = ::Charging::Http.get('/account/', token)

      return load_null_service_account_for response if response.code != 200

      self.load_service_account_for response
    rescue RestClient::Exception => exception
      load_null_service_account_for exception.response
    end

    def initialize(attributes, response) # :nodoc:
      attributes.each do |attr, value|
        instance_variable_set("@#{attr}", value)
      end

      @last_response = response
    end

    private

    def self.load_null_service_account_for(response)
      NullServiceAccount.new(response)
    end

    def self.load_service_account_for(response)
      data = MultiJson.decode(response.body)
      self.new(data, response)
    end

    def attributes
      ATTRIBUTES.inject({}) do |hash, attribute|
        hash[attribute] = send(attribute)
        hash
      end
    end
  end
end
