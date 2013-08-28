# encoding: utf-8
require 'spec_helper'

describe Charging::Configuration do
  context 'for default settings' do
    its(:host) { should eql 'charging.finnanceconnect.com.br' }
    its(:application_token) { should be_nil }
    its(:user_agent) { should match /Charging Ruby Client v\d+\.\d+\.\d+/ }
    its(:valid?) { should be_false }
  end

  context 'with application_token' do
    subject do
      Charging::Configuration.new.tap {|c| c.application_token = 'some-token'}
    end

    its(:valid?) { should be_true }
  end
end
