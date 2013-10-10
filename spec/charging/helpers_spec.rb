# encoding: utf-8

require 'spec_helper'

describe Charging::Helpers do
  attr_reader :name, :address

  describe '.load_variables' do
    it 'should only load instance variables specified' do
      object = Object.new

      described_class.load_variables(object, [:name, :address, :phone], {name: 'name', 'address' => 'address', other: 'other'})

      expect(object.instance_variable_get :@name).to eq 'name'
      expect(object.instance_variable_get :@address).to eq 'address'
      expect(object.instance_variables).to include(:@name, :@address, :@phone)
      expect(object.instance_variables).to_not include(:@other)
    end
  end

  describe '.required_arguments!' do
    it 'should raise for nil value' do
      expect {
        described_class.required_arguments!(name: nil)
      }.to raise_error ArgumentError, 'name required'
    end

    it 'should not raise without nil value' do
      expect {
        described_class.required_arguments!(name: 'value')
      }.to_not raise_error
    end
  end

  describe '.hashify' do
    it 'should results a hash for attributes from a object' do
      attributes = [:name, :phones, :emails]
      object = Struct.new(*attributes).new(
        'John Doe',
        {home: '+552123456789'},
        ['john.doe@mailinator.com', 'john@doe.com']
      )

      result = described_class.hashify(object, attributes)

      expect(result).to eq(name: 'John Doe', phones: {home: '+552123456789'}, emails: ['john.doe@mailinator.com', 'john@doe.com'])
    end
  end
end
