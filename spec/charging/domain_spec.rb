# encoding: utf-8

require 'spec_helper'

describe Charging::Domain, :vcr do
  context 'for new domain' do
    let(:response_mock) { double(:response) }

      subject do
      described_class.new({
        supplier_name: 'ACME Inc',
        address: '123, Anonymous Stree',
        city_state: 'Neverland',
        zipcode: '12345-678',
        national_identifier: '76.169.284/0001-06',
        description: 'Here is a description of ACME Inc'
      }, response_mock)
    end

    its(:supplier_name) { should eq 'ACME Inc' }
    its(:address) { should eq '123, Anonymous Stree' }
    its(:city_state) { should eq  'Neverland' }
    its(:zipcode) { should eq  '12345-678' }
    its(:national_identifier) { should eq '76.169.284/0001-06' }
    its(:description) { should eq  'Here is a description of ACME Inc' }

    its(:uuid) { should be_nil }
    its(:etag) { should be_nil }
    its(:persisted?) { should be_false }
    its(:last_response) { should eq response_mock }
  end

  describe '.find_all' do
    it 'should require an account' do
      expected_error = [ArgumentError, 'service account required']

      expect { described_class.find_all(nil) }.to raise_error(*expected_error)
    end

    context 'for an account' do
      let(:account) { double('ServiceAccount', application_token: 'AwdhihciTgORGUjnkuk1vg==') }

      let(:result) do
        VCR.use_cassette('list available domains') do
          described_class.find_all(account)
        end
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
          expect(domain.uuid).to eq '154932d8-66b8-4e6b-82f5-ebb1d32fe85d'
        end
      end
    end
  end
end
