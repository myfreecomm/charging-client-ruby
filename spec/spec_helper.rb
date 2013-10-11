require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'charging'

require 'vcr'
require 'pry'

# Load all support files
Dir[File.join(File.dirname(__FILE__), 'support/*.rb')].each do |file|
  require file
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
  c.default_cassette_options = { :record => :once }
  c.configure_rspec_metadata!
end

RSpec.configure do |c|
  c.mock_with :rspec

  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  
  # so we can use :vcr rather than :vcr => true;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.before(:vcr => true) do
    Charging.configure do |config|
      config.url = 'http://sandbox.charging.financeconnect.com.br:8080'
      config.application_token = 'AwdhihciTgORGUjnkuk1vg=='
    end
    
    # uncomment below lines to turn off VCR
    WebMock.allow_net_connect!
    VCR.eject_cassette
    VCR.turn_off!(ignore_cassettes: true)
  end
  
  def current_account
    @current_account ||= Charging::ServiceAccount.current
  end
end
