# encoding: utf-8
require 'spec_helper'

describe Charging do

  it 'should have a version number' do
    Charging::VERSION.should_not be_nil
  end

  describe '.configuration' do
    it 'should user a singleton object for the configuration values' do
      expect(Charging.configuration).to eql Charging.configuration
    end
  end

  describe '.configure' do
    subject { Charging.configuration }

    before do
      Charging.configure do |c|
        c.url               = 'https://some.host'
        c.application_token = 'some-app-token'
        c.user_agent        = 'Testing with RSpec'
      end
    end

    its(:url) { should eql 'https://some.host' }
    its(:application_token) { should eql 'some-app-token'}
    its(:user_agent) { should eql 'Testing with RSpec'}
  end
end
