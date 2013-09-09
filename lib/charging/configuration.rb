# encoding: utf-8
require 'base64'

module Charging
  class Configuration
    attr_accessor :url, :user_agent, :application_token

    def initialize
      @url = 'https://charging.finnanceconnect.com.br'
      @user_agent = "Charging Ruby Client v#{Charging::VERSION}"
    end

    def application_credentials
      credentials_for(application_token, :application_token)
    end

    def credentials_for(token, attribute_name = :token)
      check_valid_token!(token, attribute_name)
      encrypted_token = ::Base64.strict_encode64(":#{token}")
      "Basic #{encrypted_token}"
    end

    private

    def check_valid_token!(token, attribute_name)
      invalid = token.nil? || token.to_s.strip.empty?
      raise(ArgumentError, "#{token.inspect} is not a valid #{attribute_name}") if invalid
      true
    end
  end
end
