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
        c.application_token = 'AppToken=='
        c.url               = 'https://some.host'
        c.user_agent        = 'Testing with RSpec'
      end
    end

    its(:application_token) { should eq 'AppToken==' }
    its(:url) { should eq 'https://some.host' }
    its(:user_agent) { should eq 'Testing with RSpec'}
  end
end
