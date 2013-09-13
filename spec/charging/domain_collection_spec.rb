# encoding: utf-8

require 'spec_helper'

describe Charging::DomainCollection, :vcr do
  it 'should raise for invalid account' do
    expected_error = [ArgumentError, 'service account required']

    expect { described_class.new(nil, nil) }.to raise_error *expected_error
  end
end
