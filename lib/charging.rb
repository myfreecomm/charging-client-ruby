# encoding: utf-8

require 'rest_client'
require 'multi_json'

require 'charging/version'
require 'charging/helpers'
require 'charging/configuration'
require 'charging/http'

require 'charging/service_account'

module Charging
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
end
