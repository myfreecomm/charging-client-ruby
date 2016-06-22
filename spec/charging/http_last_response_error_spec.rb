# encoding: utf-8
require 'spec_helper'

describe Charging::Http::LastResponseError do
  let(:mock_response) { double(:some_http_response, to_s: 'called to_s from mock response') }

  subject { described_class.new(mock_response) }

  describe '#last_response' do
    subject { super().last_response }
    it { is_expected.to eq mock_response }
  end

  describe '#message' do
    subject { super().message }
    it { is_expected.to eq 'called to_s from mock response'}
  end
end
