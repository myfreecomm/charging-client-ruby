# encoding: utf-8

require 'spec_helper'

describe Charging::Domain::Collection, :vcr do
  it 'should raise for invalid account' do
    expected_error = [ArgumentError, 'account required']

    expect { described_class.new(nil, double(:response, code: 401)) }.to raise_error(*expected_error)
  end

  it 'should raise for invalid response' do
    VCR.use_cassette('DomainCollection/invalid response for domain collection') do
      expected_error = [ArgumentError, 'response required']

      expect { described_class.new(current_account, nil) }.to raise_error(*expected_error)
    end
  end

  context 'with not success response' do
    let(:response_not_found) { double(:response_not_found, code: 404) }

    let!(:result) do 
      VCR.use_cassette('DomainCollection/not found response for domain collection') do
        described_class.new(current_account, response_not_found)
      end
    end

    it 'should have empty content' do
      expect(result).to be_empty
    end

    it 'should have last response' do
      expect(result.last_response).to eq response_not_found
    end
  end

  context 'with success response without data' do
    let(:response_success) do
      double(code: 200, body: '[]')
    end

    let!(:result) do
      VCR.use_cassette('DomainCollection/success response without data for domain collection') do
        described_class.new(current_account, response_success)
      end
    end

    it 'should have empty content' do
      expect(result).to be_empty
    end

    it 'should have last response' do
      expect(result.last_response).to eq response_success
    end
  end

  context 'with success response with data' do
    let(:body) do
      MultiJson.encode([{
        supplier_name: 'supplier_name data',
        address: 'address data',
        city_state: 'city_state data',
        zipcode: 'zipcode data',
        national_identifier: 'national_identifier data',
        description: 'description data',
        uuid: '154932d8-66b8-4e6b-82f5-ebb1d32fe85d',
        etag: 'e11877e49b4ac65b4b8d96c16012a20254312e74',
        uri: 'http://sandbox.charging.financeconnect.com.br:8080/account/domains/154932d8-66b8-4e6b-82f5-ebb1d32fe85d/'
      }])
    end

    let(:response_success) do
      double(code: 200, body: body)
    end

    let!(:result) do
      VCR.use_cassette('DomainCollection/success response with data for domain collection') do
        described_class.new(current_account, response_success)
      end
    end

    it 'should convert into an array of domain' do
      expect(result.size).to eq 1
    end

    it 'should have last response' do
      expect(result.last_response).to eq response_success
    end

    it 'should contain a domain' do
      domain = result.first

      expect(domain).to be_an_instance_of(Charging::Domain)
    end

    it 'should load current account for domain instance' do
      expect(result.first.account).to eq current_account
    end
  end
end
