# encoding: utf-8
require 'spec_helper'

describe Charging::Configuration do
  let(:application_token) { 'some-app-token' }
  let(:config) { Charging::Configuration.new }

  context 'for default settings' do
    its(:application_token) { should be_nil }
    its(:url) { should eq 'https://charging.financeconnect.com.br' }
    its(:user_agent) { should match(/Charging Ruby Client v\d+\.\d+\.\d+/) }
  end

  context "with configuration parameters" do
    subject do
      Charging::Configuration.new.tap do |config|
        config.application_token = application_token
        config.url               = 'https://sandbox.app.charging.com.br'
        config.user_agent        = 'My amazing app'
      end
    end

    its(:application_token) { should eq application_token }
    its(:url) { should eq 'https://sandbox.app.charging.com.br'}
    its(:user_agent) { should eq "My amazing app" }
  end

  describe "#credentials_for" do
    [nil, '', ' '].each do |invalid_token|
      it "should reject #{invalid_token.inspect} as token" do
        expect { config.credentials_for(invalid_token) }.to raise_error(ArgumentError, "#{invalid_token.inspect} is not a valid token")
      end
    end

    it 'should generate credential for token' do
      expect(config.credentials_for(application_token)).to eq "Basic OnNvbWUtYXBwLXRva2Vu"
    end
  end
end
