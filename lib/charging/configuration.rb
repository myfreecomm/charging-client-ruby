# encoding: utf-8
require 'base64'

module Charging
  class Configuration
    attr_accessor :url, :user_agent

    def initialize
      @url = 'https://charging.financeconnect.com.br'
      @user_agent = "Charging Ruby Client v#{Charging::VERSION}"
    end

    def credentials_for(token)
      check_valid_token!(token)
      encrypted_token = ::Base64.strict_encode64(":#{token}")
      "Basic #{encrypted_token}"
    end

    private

    def check_valid_token!(token)
      invalid = token.nil? || token.to_s.strip.empty?
      raise(ArgumentError, "#{token.inspect} is not a valid token") if invalid
      true
    end
  end
end
