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

  describe '.request_to_api' do
    %w[post put patch].each do |method|
      context 'with body as json' do
        it "should use RestClient.#{method} with the supplied params and common options" do
          expect(RestClient).to receive(method).with(
            "#{configuration.url}/foo",
            '{"hello":"world"}',
            params: {},
            authorization: 'Basic OnNvbWUtYXBwLXRva2Vu',
            content_type: :json,
            accept: :json,
            user_agent: configuration.user_agent
          ).and_return(mock_response)

          described_class.request_to_api(method, '/foo', {}, 'some-app-token', {hello: 'world'})
        end
      end

      context 'with body as string' do
        it 'should use RestClient.post with the supplied params and common options' do
          expect(RestClient).to receive(method).with(
            "#{configuration.url}/foo",
            '{"hello":"world"}',
            params: {},
            authorization: 'Basic OnNvbWUtYXBwLXRva2Vu',
            content_type: :json,
            accept: :json,
            user_agent: configuration.user_agent
          ).and_return(mock_response)

          described_class.request_to_api(method, '/foo', {}, 'some-app-token', '{"hello":"world"}')
        end
      end
    end
  end

  describe ".delete"  do
    it 'should delegate to request_to_api' do
      expect(Charging::Http).to receive(:request_to_api).with(
        :delete,
        '/foo',
        {etag: 'etag'},
        'some-app-token'
      )

      described_class.delete('/foo', 'some-app-token', 'etag')
    end
  end

  describe ".get"  do
    it 'should delegate to request_to_api' do
      expect(Charging::Http).to receive(:request_to_api).with(
        :get,
        '/foo',
        {},
        'some-app-token'
      )

      described_class.get('/foo', 'some-app-token')
    end
  end

  %w[post].each do |method|
    describe ".#{method}"  do
      it 'should delegate to request_to_api' do
        expect(Charging::Http).to receive(:request_to_api).with(
          method.to_sym,
          '/foo',
          {spam: 'eggs'},
          'some-app-token',
          'body'
        )

        described_class.send(method, '/foo', 'some-app-token', 'body', spam: 'eggs')
      end
    end
  end
  
  %w[put patch].each do |method|
    describe ".#{method}"  do
      it 'should delegate to request_to_api' do
        expect(Charging::Http).to receive(:request_to_api).with(
          method.to_sym,
          '/foo',
          {etag: 'etag'},
          'some-app-token',
          'body'
        )

        described_class.send(method, '/foo', 'some-app-token', 'etag', 'body')
      end
    end
  end

  specify('.charging_path') do
    expect(described_class.charging_path('/path')).to eql "#{configuration.url}/path"
  end

  describe '.common_params' do
    context 'without etag' do
      it 'should to return a hash with request headers' do
        expect(described_class.common_params('token', nil)).to eql({
          accept: :json,
          authorization: 'Basic OnRva2Vu',
          content_type: :json,
          user_agent: configuration.user_agent
        })
      end
    end

    context 'with etag' do
      it 'should to return a hash with request headers' do
        expect(described_class.common_params('token', 'etag')).to eql({
          accept: :json,
          authorization: 'Basic OnRva2Vu',
          content_type: :json,
          user_agent: configuration.user_agent,
          'If-Match' => 'etag'
        })
      end
    end
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
          expect(mock).not_to receive(:follow_redirection)
          expect(mock).to receive(:return!)
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
            expect(mock).to receive(:follow_redirection)
            expect(mock).not_to receive(:return!)
          end

          described_class.should_follow_redirect.call(response, nil, nil)
        end
      end
    end
  end
end
