# encoding: utf-8
require 'spec_helper'

describe Charging::Http do
  let(:mock_response) { double('restclient http response') }
  let(:configuration) { Charging.configuration }

  describe '.basic_credential_for' do
    it 'should accept only user' do
      expect(described_class.basic_credential_for('user')).to eql 'Basic dXNlcg=='
    end

    it 'should accept user and password' do
      expect(described_class.basic_credential_for('user', 'pass')).to eql 'Basic dXNlcjpwYXNz'
    end
  end

  describe '.request_with_body' do
    %w[post put patch].each do |method|
      context 'with body as json' do
        it "should use RestClient.#{method} with the supplied params and common options" do
          RestClient.should_receive(method).with(
            'https://charging.financeconnect.com.br/foo',
            '{"hello":"world"}',
            params: {},
            authorization: 'Basic OnNvbWUtYXBwLXRva2Vu',
            content_type: :json,
            accept: :json,
            user_agent: configuration.user_agent
          ).and_return(mock_response)

          described_class.request_with_body(method, '/foo', {hello: 'world'}, {}, 'some-app-token')
        end
      end

      context 'with body as string' do
        it 'should use RestClient.post with the supplied params and common options' do
          RestClient.should_receive(method).with(
            'https://charging.financeconnect.com.br/foo',
            '{"hello":"world"}',
            params: {},
            authorization: 'Basic OnNvbWUtYXBwLXRva2Vu',
            content_type: :json,
            accept: :json,
            user_agent: configuration.user_agent
          ).and_return(mock_response)

          described_class.request_with_body(method, '/foo', '{"hello":"world"}', {}, 'some-app-token')
        end
      end
    end
  end

  describe '.request_without_body' do
    %w[get delete].each do |method|
      it "should use RestClient.#{method} with the supplied params and common options" do
        RestClient.should_receive(method).with(
          'https://charging.financeconnect.com.br/foo',
          params: {spam: 'eggs'},
          authorization: 'Basic OnNvbWUtYXBwLXRva2Vu',
          content_type: :json,
          accept: :json,
          user_agent: configuration.user_agent
        ).and_return(mock_response)

        described_class.request_without_body(method, '/foo', {spam: 'eggs'}, 'some-app-token')
      end
    end
  end

  describe ".delete"  do
    it 'should delegate to request_without_body' do
      Charging::Http.should_receive(:request_without_body).with(
        :delete,
        '/foo',
        {},
        'some-app-token',
        :no_follow
      )

      described_class.delete('/foo', 'some-app-token')
    end
  end

  describe ".get"  do
    it 'should delegate to request_without_body' do
      Charging::Http.should_receive(:request_without_body).with(
        :get,
        '/foo',
        {},
        'some-app-token'
      )

      described_class.get('/foo', 'some-app-token')
    end
  end

  %w[post put patch].each do |method|
    describe ".#{method}"  do
      it 'should delegate to request_with_body' do
        Charging::Http.should_receive(:request_with_body).with(
          method.to_sym,
          '/foo',
          'body',
          {spam: 'eggs'},
          'some-app-token'
        )

        described_class.send(method, '/foo', 'some-app-token', 'body', spam: 'eggs')
      end
    end
  end

  specify('.charging_path') do
    expect(described_class.charging_path('/path')).to eql 'https://charging.financeconnect.com.br/path'
  end

  specify('.common_params') do
    expect(described_class.common_params('token')).to eql({
      accept: :json,
      authorization: 'Basic OnRva2Vu',
      content_type: :json,
      user_agent: configuration.user_agent
    })
  end

  describe '.encoded_body' do
    context 'with hash body' do
      it 'should convert to string in json format' do
        expect(described_class.encoded_body({some: 'value'})).to eql('{"some":"value"}')
      end
    end

    context 'with string body' do
      it 'should repass the original body' do
        expect(described_class.encoded_body('some text')).to eql('some text')
      end
    end
  end

  describe '.should_follow_redirect' do
    context 'on success response code (200)' do
      it 'should call return on response' do
        response = double(code: 200).tap do |mock|
          mock.should_not_receive(:follow_redirection)
          mock.should_receive(:return!)
        end

        described_class.should_follow_redirect.call(response, nil, nil)
      end
    end

    {
      301 => 'moved permanently',
      302 => 'found',
      307 => 'temporary redirect'
    }.each do |status_code, status_message|
      context "on #{status_message} response code (#{status_code})" do
        it 'should call follow redirection on response' do
          response = double(code: status_code).tap do |mock|
            mock.should_receive(:follow_redirection)
            mock.should_not_receive(:return!)
          end

          described_class.should_follow_redirect.call(response, nil, nil)
        end
      end
    end
  end
end
