# encoding: utf-8
require 'spec_helper'

describe Charging::Configuration do
  let(:application_token) { 'some-app-token' }
  let(:config) { Charging::Configuration.new }

  context 'for default settings' do
    describe '#application_token' do
      subject { super().application_token }
      it { is_expected.to be_nil }
    end

    describe '#url' do
      subject { super().url }
      it { is_expected.to eq 'https://charging.financeconnect.com.br' }
    end

    describe '#user_agent' do
      subject { super().user_agent }
      it { is_expected.to match(/Charging Ruby Client v\d+\.\d+\.\d+/) }
    end
  end

  context "with configuration parameters" do
    subject do
      Charging::Configuration.new.tap do |config|
        config.application_token = application_token
        config.url               = 'https://sandbox.app.charging.com.br'
        config.user_agent        = 'My amazing app'
      end
    end

    describe '#application_token' do
      subject { super().application_token }
      it { is_expected.to eq application_token }
    end

    describe '#url' do
      subject { super().url }
      it { is_expected.to eq 'https://sandbox.app.charging.com.br'}
    end

    describe '#user_agent' do
      subject { super().user_agent }
      it { is_expected.to eq "My amazing app" }
    end
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
