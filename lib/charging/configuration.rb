# encoding: utf-8

module Charging
  class Configuration
    attr_accessor :host, :application_token, :user_agent

    def initialize
      @host = 'charging.finnanceconnect.com.br'
      @user_agent = "Charging Ruby Client v#{Charging::VERSION}"
    end

    def valid?
      !application_token.nil?
    end
  end
end
