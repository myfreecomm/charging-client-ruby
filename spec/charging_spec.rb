# encoding: utf-8
require 'spec_helper'

describe Charging do

  it 'should have a version number' do
    expect(Charging::VERSION).not_to be_nil
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

    describe '#application_token' do
      subject { super().application_token }
      it { is_expected.to eq 'AppToken==' }
    end

    describe '#url' do
      subject { super().url }
      it { is_expected.to eq 'https://some.host' }
    end

    describe '#user_agent' do
      subject { super().user_agent }
      it { is_expected.to eq 'Testing with RSpec'}
    end
  end
end
