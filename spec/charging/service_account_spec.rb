# encoding: utf-8
require 'spec_helper'

describe Charging::ServiceAccount, :vcr do
  describe '.find' do
    context 'with an invalid application token' do
      it 'should raise a last response error' do
        VCR.use_cassette('invalid request for get current account') do
          error = [Charging::Http::LastResponseError, /401 Unauthorized/]

          expect { described_class.find('invalid-token') }.to raise_error(*error)
        end
      end
    end

    context 'with a valid application token' do
      before do
        VCR.use_cassette('valid request for get current account') do
          @result = described_class.find('AwdhihciTgORGUjnkuk1vg==')
        end
      end

      it 'should return a ServiceAccount instance' do
        expect(@result).to be_an_instance_of(Charging::ServiceAccount)
      end

      context 'with current service account' do
        subject { @result }

        its(:plan) { should eql 'full' }
        its(:name) { should eql 'Teste cliente Ruby' }
        its(:uri)  { should eql 'http://sandbox.app.passaporteweb.com.br/organizations/api/accounts/3a0676fb-6639-466a-ac35-9ea7c5f67386/' }
        its(:uuid) { should eql '3a0676fb-6639-466a-ac35-9ea7c5f67386' }
      end

      it 'should return ok (200) response at last response' do
        last_response = @result.last_response

        expect(last_response.code).to eql 200
      end
    end
  end
end
