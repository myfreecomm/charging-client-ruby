# encoding: utf-8

require 'spec_helper'

describe Charging::ChargeAccount::Collection do
  let(:domain_mock) { double(:domain, token: 'QNTGvpnYRVC4HbHibDBUIQ==') }

  it 'should raise for invalid account' do
    expected_error = [ArgumentError, 'domain required']

    expect { described_class.new(nil, double(:response, code: 401)) }.to raise_error(*expected_error)
  end

  it 'should raise for invalid response' do
    expected_error = [ArgumentError, 'response required']

    expect { described_class.new(domain_mock, nil) }.to raise_error(*expected_error)
  end

  context 'with not success response' do
    let(:response_not_found) { double(:response_not_found, code: 404) }

    let!(:result) { described_class.new(domain_mock, response_not_found) }

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

    let!(:result) { described_class.new(domain_mock, response_success) }

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
        account: { digit: "8", number: 1234 },
        address: "new address",
        advance_days: 10,
        agency: { digit: "", number: 354 },
        agreement_code: "1234",
        bank: "237",
        currency: 9,
        etag: "9c8d4ad41a67770c79ace62b9515adf8b5b0a589",
        name: "Conta de Cobrança no Bradesco",
        national_identifier: "03.448.307/9170-25",
        portfolio_code: "25",
        sequence_numbers: [ 1, 9999999 ],
        supplier_name: "Springfield Elemenary School",
        uri: "http://sandbox.charging.financeconnect.com.br/charge-accounts/29e77bc5-0e70-444c-a922-3149e78d905b/",
        uuid: "29e77bc5-0e70-444c-a922-3149e78d905b"
      }])
    end

    let(:response_success) do
      double(code: 200, body: body)
    end

    let(:result) { described_class.new(domain_mock, response_success) }

    it 'should convert into an array of domain' do
      expect(result.size).to eq 1
    end

    it 'should have last response' do
      expect(result.last_response).to eq response_success
    end

    it 'should contain a domain' do
      domain = result.first

      expect(domain).to be_an_instance_of(Charging::ChargeAccount)
    end

    it 'should load current account for domain instance' do
      expect(result.first.domain).to eq domain_mock
    end
  end
end
