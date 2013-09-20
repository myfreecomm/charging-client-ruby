# encoding: utf-8

require 'spec_helper'

describe Charging::Domain, :vcr do
  let(:account) { double('ServiceAccount', application_token: 'AwdhihciTgORGUjnkuk1vg==') }
  let(:uuid) { '335ca81f-626f-44e2-9b72-da98333166b3' }
  let!(:national_identifier) { Faker.cnpj_generator }

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
      }, account, response_mock)
    end

    %w[supplier_name address city_state zipcode national_identifier description].each do |attr|
      its(attr) { should eq "#{attr} data"}
    end

    %w[uri uuid etag token].each { |attr| its(attr) { should be_nil } }

    its(:last_response) { should eq response_mock }

    its(:persisted?) { should be_false }

    its(:account) { should eq account }

    its(:attributes) { should eq({
      address: 'address data',
      city_state: 'city_state data',
      description: 'description data',
      national_identifier: 'national_identifier data',
      supplier_name: 'supplier_name data',
      zipcode: 'zipcode data'
    }) }
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
          expect(domain.etag).to eq '7145f1a617cb7a7a0089035d9f3a6db6aa56f8ee'
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

    it 'should require an uuid' do
      expected_error = [ArgumentError, 'uuid required']

      expect { described_class.find_by_uuid(account, nil) }.to raise_error(*expected_error)
    end

    it 'should raise for invalid uuid' do
      VCR.use_cassette('domain by uuid not found via account') do
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
        VCR.use_cassette('finding a domain by uuid via account') do
          described_class.find_by_uuid(account, uuid)
        end
      end

      it 'should instanciate a domain' do
        expect(subject).to be_an_instance_of(Charging::Domain)
      end

      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      its(:uri) { should eq "http://sandbox.charging.financeconnect.com.br/account/domains/#{uuid}/" }
      its(:uuid) { should eq uuid }
      its(:etag) { should eq '7145f1a617cb7a7a0089035d9f3a6db6aa56f8ee' }
      its(:token) { should eq '/VWsCyHHRrOF+pKv0Pbyfg==' }
      its(:account) { should eq account }
    end
  end

  describe '.find_by_token' do
    let(:domain_token) { '/VWsCyHHRrOF+pKv0Pbyfg==' }

    it 'should require a token' do
      expected_error = [ArgumentError, 'token required']

      expect { described_class.find_by_token(nil) }.to raise_error(*expected_error)
    end

    it 'should raise for invalid uuid' do
      VCR.use_cassette('domain by token unauthorized') do
        expect { described_class.find_by_token('invalid-token') }.to raise_error Charging::Http::LastResponseError
      end
    end

    context 'for a valid domain token' do
      subject do
        VCR.use_cassette('finding a domain by token') do
          described_class.find_by_token(domain_token)
        end
      end

      it 'should instanciate a domain' do
        expect(subject).to be_an_instance_of(Charging::Domain)
      end

      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      its(:uri) { should eq "http://sandbox.charging.financeconnect.com.br/account/domains/#{uuid}/" }
      its(:uuid) { should eq uuid }
      its(:etag) { should eq '7145f1a617cb7a7a0089035d9f3a6db6aa56f8ee' }
      its(:token) { should eq '/VWsCyHHRrOF+pKv0Pbyfg==' }
      its(:account) { should be_nil }
    end
  end

  describe '#create!' do
    let(:attributes) do
      {
        supplier_name: 'Springfield Elemenary School',
        address: '1608 Florida Avenue',
        city_state: 'Greenwood/SC',
        zipcode: '29646',
        national_identifier: national_identifier,
        description: 'The mission of Greenwood School District 50 is to educate all students to become responsible and productive citizens.',
      }
    end

    it 'should require an account and load errors' do
      invalid_domain = described_class.new(attributes, nil)

      expect(invalid_domain.errors).to be_empty

      expected_error = [StandardError, 'can not create without a service account']
      expect { invalid_domain.create! }.to raise_error *expected_error

      expect(invalid_domain.errors).to_not be_empty
    end

    context 'when API responds with 409 Conflict' do
      it 'should raise Http::LastResponseError, and load errors and last response' do
        attributes[:national_identifier] = '73.331.840/0001-00'
        domain = described_class.new(attributes, account)

        VCR.use_cassette('conflict to create a domain') do
          expect(domain.errors).to be_empty
          expect(domain.last_response).to be_nil

          expect {
            domain.create!
          }.to raise_error Charging::Http::LastResponseError

          expect(domain.errors).to_not be_empty
          expect(domain.last_response.code).to eq 409
        end
      end
    end

    context 'when everything is OK' do
      subject { described_class.new(attributes, account) }

      before do
        VCR.use_cassette('creating a domain') do
          subject.create!
        end
      end

      %i[uuid uri etag token].each do |attribute|
        its(attribute) { should_not be_nil }
      end

      it 'should be persisted' do
        expect(subject).to be_persisted
      end
    end
  end
end
