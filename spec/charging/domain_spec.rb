# encoding: utf-8

require 'spec_helper'

describe Charging::Domain, :vcr do
  let(:account) { double('ServiceAccount', application_token: 'AwdhihciTgORGUjnkuk1vg==') }
  let(:uuid) { '154932d8-66b8-4e6b-82f5-ebb1d32fe85d' }

  context 'for new domain instance' do
    let(:response_mock) { double(:response) }

    subject do
      described_class.new({
        supplier_name: 'supplier_name data',
        address: 'address data',
        city_state: 'city_state data',
        zipcode: 'zipcode data',
        national_identifier: 'national_identifier data',
        description: 'description data',
      }, response_mock)
    end

    %w[supplier_name address city_state zipcode national_identifier description].each do |attr|
      its(attr) { should eq "#{attr} data"}
    end

    %w[uri uuid etag token].each { |attr| its(attr) { should be_nil } }

    its(:last_response) { should eq response_mock }

    its(:persisted?) { should be_false }
  end

  describe '.find_all' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'service account required']

      expect { described_class.find_all(nil) }.to raise_error(*expected_error)
    end

    context 'for an account' do
      let(:result) do
        VCR.use_cassette('list available domains') do
          described_class.find_all(account)
        end
      end

      it 'should result be a domain collection instance' do
        expect(result).to be_an_instance_of(Charging::DomainCollection)

      end

      it 'should contain only one domain' do
        expect(result.size).to eq 1
      end

      it 'should contain last response information' do
        expect(result.last_response.code).to eq 200
      end

      context 'on first element result' do
        let(:domain) { result.first }

        it 'should be a persisted domain' do
          expect(domain).to be_persisted
        end

        it 'should contain etag' do
          expect(domain.etag).to eq 'e11877e49b4ac65b4b8d96c16012a20254312e74'
        end

        it 'should contain uuid' do
          expect(domain.uuid).to eq uuid
        end

        it 'should contain uri' do
          expect(domain.uri).to eq "http://sandbox.charging.financeconnect.com.br/account/domains/#{uuid}/"
        end
      end
    end
  end

  describe '.find_by_uuid' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'service account required']

      expect { described_class.find_by_uuid(nil, '') }.to raise_error(*expected_error)
    end

    it 'should raise for invalid uuid' do
      VCR.use_cassette('domain not found') do
        expect { described_class.find_by_uuid(account, 'invalid-uuid') }.to raise_error Charging::Http::LastResponseError
      end
    end

    it 'should raise if not response to success (200)' do
      response_mock = double('AcceptedResponse', code: 202, to_s: 'AcceptedResponse')

      described_class
        .should_receive(:get_account_domain)
        .with(account, uuid)
        .and_return(response_mock)

      expect {
        described_class.find_by_uuid(account, uuid)
      }.to raise_error Charging::Http::LastResponseError, 'AcceptedResponse'
    end

    context 'for a valid uuid' do
      subject do
        VCR.use_cassette('finding a domain via account') do
          described_class.find_by_uuid(account, uuid)
        end
      end

      it 'should instanciate a domain' do
        expect(subject).to be_an_instance_of(Charging::Domain)
      end

      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      its(:uri) { should eq 'http://sandbox.charging.financeconnect.com.br/account/domains/154932d8-66b8-4e6b-82f5-ebb1d32fe85d/' }
      its(:uuid) { should eq uuid }
      its(:etag) { should eq 'e11877e49b4ac65b4b8d96c16012a20254312e74' }
      its(:token) { should eq '74QaWW3uSWKPPJVsBgBR6w==' }
      its(:account) { should eq account }
    end
  end
end
