# encoding: utf-8

# http://www.ruby-doc.org/stdlib-2.0.0/libdoc/English/rdoc/English.html
require 'English'

require 'rest_client'
require 'multi_json'

require 'charging/version'
require 'charging/helpers'
require 'charging/configuration'
require 'charging/http'

require 'charging/collection'
require 'charging/base'
require 'charging/service_account'
require 'charging/domain'
require 'charging/charge_account'
require 'charging/invoice'

module Charging
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
  
  def self.use_sandbox!(application_token = 'AwdhihciTgORGUjnkuk1vg==')
    Charging.configure do |config|
      config.url = 'http://sandbox.charging.financeconnect.com.br:8080'
      config.application_token = application_token
    end    
  end
end
