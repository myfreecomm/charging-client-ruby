# encoding: utf-8
require 'spec_helper'

describe Charging::Http::LastResponseError do
  let(:mock_response) { double(:some_http_response, to_s: 'called to_s from mock response') }

  subject { described_class.new(mock_response) }

  its(:last_response) { should eq mock_response }
  its(:message) { should eq 'called to_s from mock response'}
end
