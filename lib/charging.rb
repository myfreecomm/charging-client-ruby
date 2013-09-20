# encoding: utf-8

# http://www.ruby-doc.org/stdlib-2.0.0/libdoc/English/rdoc/English.html
require 'English'

require 'rest_client'
require 'multi_json'

require 'charging/version'
require 'charging/helpers'
require 'charging/configuration'
require 'charging/http'

require 'charging/service_account'
require 'charging/domain'

module Charging
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
end
