# encoding: utf-8
require 'spec_helper'

describe Charging::Configuration do
  let(:config) { Charging::Configuration.new }

  context 'for default settings' do
    its(:url) { should eql 'https://charging.finnanceconnect.com.br' }
    its(:application_token) { should be_nil }
    its(:user_agent) { should match /Charging Ruby Client v\d+\.\d+\.\d+/ }
  end

  context "with configuration parameters" do
    subject do
      Charging::Configuration.new.tap do |config|
        config.url               = 'https://sandbox.app.charging.com.br'
        config.application_token = 'some-app-token'
        config.user_agent        = 'My amazing app'
      end
    end

    its(:url) { should eql 'https://sandbox.app.charging.com.br'}
    its(:application_token)  { should eql 'some-app-token' }
    its(:user_agent) { should eql "My amazing app" }
  end

  describe "#application_credentials" do
    it "should return the HTTP Basic Auth header value for the application login" do
      config.application_token = 'some-app-token'

      config.application_credentials.should eql 'Basic OnNvbWUtYXBwLXRva2Vu'
    end

    [nil, '', ' '].each do |invalid_token|
      it "should reject #{invalid_token.inspect} as an application token" do
        config.application_token = invalid_token

        expect { config.application_credentials }.to raise_error(ArgumentError, "#{invalid_token.inspect} is not a valid application_token")
      end
    end
  end

  describe "#credentials_for" do
    [nil, '', ' '].each do |invalid_token|
      it "should reject #{invalid_token.inspect} as token" do
        expect { config.credentials_for(invalid_token) }.to raise_error(ArgumentError, "#{invalid_token.inspect} is not a valid token")
      end
    end

    it 'should generate credential for token' do
      expect(config.credentials_for('some-app-token')).to eql("Basic OnNvbWUtYXBwLXRva2Vu")
    end
  end
end
