# encoding: utf-8

require 'spec_helper'

describe Charging::Domain, :vcr do
  let(:national_identifier) { Faker.cnpj_generator }
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
  let(:domain) do
    described_class.new(attributes, current_account).create!
  end

  context 'for new domain instance' do
    let(:response_mock) { double(:response, code: 500) }

    subject do
      VCR.use_cassette('Domain/for new instance') do
        described_class.new({
          supplier_name: 'supplier_name data',
          address: 'address data',
          city_state: 'city_state data',
          zipcode: 'zipcode data',
          national_identifier: 'national_identifier data',
          description: 'description data',
        }, current_account, response_mock)
      end
    end

    %w[supplier_name address city_state zipcode national_identifier description].each do |attr|
      describe attr do
        subject { super().send(attr) }
        it { is_expected.to eq "#{attr} data"}
      end
    end

    %w[uri uuid etag token].each do |attr|
      describe attr do
        subject { super().send(attr) }
        it { is_expected.to be_nil }
      end
    end

    describe '#last_response' do
      subject { super().last_response }
      it { is_expected.to eq response_mock }
    end

    describe '#persisted?' do
      subject { super().persisted? }
      it { is_expected.to be_falsey }
    end

    describe '#deleted?' do
      subject { super().deleted? }
      it { is_expected.to be_falsey }
    end

    describe '#account' do
      subject { super().account }
      it { is_expected.to eq current_account }
    end

    describe '#attributes' do
      subject { super().attributes }
      it { is_expected.to eq({
      address: 'address data',
      city_state: 'city_state data',
      description: 'description data',
      national_identifier: 'national_identifier data',
      supplier_name: 'supplier_name data',
      zipcode: 'zipcode data'
    }) }
    end
  end

  describe '#create!' do
    it 'should require an account and load errors' do
      invalid_domain = described_class.new(attributes, nil)

      expect(invalid_domain.errors).to be_empty

      expected_error = [StandardError, 'can not create without a service account']
      expect { invalid_domain.create! }.to raise_error(*expected_error)

      expect(invalid_domain.errors).to eq ['can not create without a service account']
    end

    context 'when API responds with 409 Conflict' do
      it 'should raise Http::LastResponseError, and load errors and last response' do
        VCR.use_cassette('Domain/conflict to create a domain') do
          domain
          domain = described_class.new(attributes, current_account)

          expect {
            domain.create!
          }.to raise_error Charging::Http::LastResponseError

          expect(domain.errors).to_not be_empty
          expect(domain.last_response.code).to eq 409
        end
      end
    end

    context 'when everything is OK' do
      before do
        VCR.use_cassette('Domain/creating a domain') do
          @domain = described_class.new(attributes, current_account)
          @domain.create!
        end
      end

      subject { @domain }

      [:uuid, :uri, :etag, :token].each do |attribute|
        describe attribute do
          subject { super().send(attribute) }
          it { is_expected.not_to be_nil }
        end
      end

      it 'should be persisted' do
        expect(subject).to be_persisted
      end
    end
  end

  describe '#destroy!' do
    it 'should require an account and load errors' do
      invalid_domain = described_class.new(attributes, nil)

      expect(invalid_domain.errors).to be_empty

      expected_error = [StandardError, 'can not destroy without a service account']
      expect { invalid_domain.destroy! }.to raise_error(*expected_error)

      expect(invalid_domain.errors).to eq ['can not destroy without a service account']
    end

    it 'should require a persisted domain' do
      VCR.use_cassette('Domain/try destroy a new instance') do
        not_persisted_domain = described_class.new(attributes, current_account)

        expect(not_persisted_domain).to_not be_persisted

        expected_error = [StandardError, 'can not destroy a not persisted domain']

        expect {
          not_persisted_domain.destroy!
        }.to raise_error(*expected_error)

        expect(not_persisted_domain.errors).to eq ['can not destroy a not persisted domain']
      end
    end

    it 'should raise Http::LastResponseError for domains already deleted' do
      VCR.use_cassette('Domain/try delete invalid domain') do
        expect { domain.destroy! }.to_not raise_error

        domain.instance_variable_set :@deleted, false
        domain.instance_variable_set :@persisted, true

        expect {
          domain.destroy!
        }.to raise_error Charging::Http::LastResponseError
      end

      expect(domain.last_response.code).to eq 404
    end

    it 'should delete an exist domain' do
      VCR.use_cassette('Domain/deleting a domain') do
        expect(domain).to be_persisted
        expect(domain).to_not be_deleted

        expect(domain.destroy!).to_not raise_error

        expect(domain).to_not be_persisted
        expect(domain).to be_deleted
      end
    end
  end

  describe '.find_all' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'service account required']
      expect { described_class.find_all(nil) }.to raise_error(*expected_error)
    end

    context 'for an account' do
      before do
        VCR.use_cassette('Domain/list all available domains') do
          @domain = domain # loading a domain
          @result = described_class.find_all(current_account)
          @first_result = @result.first
        end
      end

      it 'should result be a domain collection instance' do
        expect(@result).to be_an_instance_of(Charging::Domain::Collection)
      end

      it 'should contain only one domain' do
        expect(@result.size).to_not eq 0
      end

      it 'should contain last response information' do
        expect(@result.last_response.code).to eq 200
      end

      context 'on first element result' do
        it 'should be a persisted domain' do
          expect(@first_result).to be_persisted
        end

        it 'should contain etag' do
          expect(@first_result.etag).to_not be_nil
        end

        it 'should contain uuid' do
          expect(@first_result.uuid).to_not be_nil
        end

        it 'should contain uri' do
          expect(@first_result.uri).to_not be_nil
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
      VCR.use_cassette('Domain/try find a domain by uuid with nil value') do
        expected_error = [ArgumentError, 'uuid required']


        expect { described_class.find_by_uuid(current_account, nil) }.to raise_error(*expected_error)
      end
    end

    it 'should raise for invalid uuid' do
      VCR.use_cassette('Domain/not found a domain by uuid') do
        expect { described_class.find_by_uuid(current_account, 'invalid-uuid') }.to raise_error Charging::Http::LastResponseError
      end
    end

    it 'should raise if not response to success (200)' do
      VCR.use_cassette('Domain/find by uuid with response not success') do
        uuid = domain.uuid

        response_mock = double('AcceptedResponse', code: 202, to_s: 'AcceptedResponse')

        expect(described_class)
          .to receive(:get_account_domain)
          .with(current_account, uuid)
          .and_return(response_mock)

        expect {
          described_class.find_by_uuid(current_account, uuid)
        }.to raise_error Charging::Http::LastResponseError, 'AcceptedResponse'
      end
    end

    context 'for a valid uuid' do
      before do
        VCR.use_cassette('Domain/finding a domain by uuid via account') do
          @current_account = current_account
          @domain = domain
          @uuid = @domain.uuid

          @finded_domain = described_class.find_by_uuid(@current_account, @uuid)
        end
      end

      subject { @finded_domain }

      it 'should instanciate a domain' do
        expect(subject).to be_an_instance_of(Charging::Domain)
      end

      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq "http://sandbox.charging.financeconnect.com.br/account/domains/#{@uuid}/" }
      end

      describe '#uuid' do
        subject { super().uuid }
        it { is_expected.to eq @uuid }
      end

      describe '#etag' do
        subject { super().etag }
        it { is_expected.to eq @domain.etag }
      end

      describe '#token' do
        subject { super().token }
        it { is_expected.to eq @domain.token }
      end

      describe '#account' do
        subject { super().account }
        it { is_expected.to eq @current_account }
      end
    end
  end

  describe '.find_by_token' do
    it 'should require a token' do
      VCR.use_cassette('Domain/try find by token with wil value') do
        expected_error = [ArgumentError, 'token required']

        expect { described_class.find_by_token(nil) }.to raise_error(*expected_error)
      end
    end

    it 'should raise for invalid uuid' do
      VCR.use_cassette('Domain/domain by token unauthorized') do
        expect { described_class.find_by_token('invalid-token') }.to raise_error Charging::Http::LastResponseError
      end
    end

    context 'for a valid domain token' do
      before do
        VCR.use_cassette('Domain/finding a domain by token') do
          @domain = domain
          @uuid = @domain.uuid
          @token = @domain.token
          @finded_domain = described_class.find_by_token(@token)
        end
      end

      subject { @finded_domain }

      it 'should instanciate a domain' do
        expect(subject).to be_an_instance_of(Charging::Domain)
      end

      it 'should be a persisted instance' do
        expect(subject).to be_persisted
      end

      describe '#uri' do
        subject { super().uri }
        it { is_expected.to eq "http://sandbox.charging.financeconnect.com.br/account/domains/#{@uuid}/" }
      end

      describe '#uuid' do
        subject { super().uuid }
        it { is_expected.to eq @uuid }
      end

      describe '#etag' do
        subject { super().etag }
        it { is_expected.to eq @domain.etag }
      end

      describe '#token' do
        subject { super().token }
        it { is_expected.to eq @token }
      end

      describe '#account' do
        subject { super().account }
        it { is_expected.to be_nil }
      end
    end
  end
end
