# encoding: utf-8
require 'spec_helper'

describe Charging::ServiceAccount, :vcr do
  describe '.current' do
    it 'should return current service account' do
      VCR.use_cassette('ServiceAccount/valid request for get current service account') do
        expect { described_class.current }.to_not raise_error
      end
    end
  end

  describe '.find_by_token' do
    context 'with an invalid application token' do
      it 'should raise a last response error' do
        VCR.use_cassette('ServiceAccount/invalid token for a service account') do
          error = [Charging::Http::LastResponseError, /401 Unauthorized/]

          expect { described_class.find_by_token('invalid-token') }.to raise_error(*error)
        end
      end
    end

    context 'with a valid application token' do
      before do
        VCR.use_cassette('ServiceAccount/valid token for a service account') do
          @result = described_class.find_by_token('AwdhihciTgORGUjnkuk1vg==')
        end
      end

      it 'should return a ServiceAccount instance' do
        expect(@result).to be_an_instance_of(Charging::ServiceAccount)
      end

      context 'with current service account' do
        subject { @result }

        describe '#plan' do
          subject { super().plan }
          it { is_expected.to eq 'full' }
        end

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq 'Teste cliente Ruby' }
        end

        describe '#uri' do
          subject { super().uri }
          it { is_expected.to eq 'http://sandbox.app.passaporteweb.com.br/organizations/api/accounts/3a0676fb-6639-466a-ac35-9ea7c5f67386/' }
        end

        describe '#uuid' do
          subject { super().uuid }
          it { is_expected.to eq '3a0676fb-6639-466a-ac35-9ea7c5f67386' }
        end

        describe '#application_token' do
          subject { super().application_token }
          it { is_expected.to eq 'AwdhihciTgORGUjnkuk1vg==' }
        end
      end

      it 'should return ok (200) response at last response' do
        last_response = @result.last_response

        expect(last_response.code).to eql 200
      end
    end
  end
end
