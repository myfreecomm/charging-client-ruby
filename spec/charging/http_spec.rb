# encoding: utf-8
require 'spec_helper'

describe Charging::Http do

  before do
    Charging.configure do |config|
      config.url               = 'http://better.place.in/the-world'
      config.application_token = 'AwdhihciTgORGUjnkuk1vg=='
      config.user_agent        = 'My Mocking App v1.1'
    end
  end

  let(:mock_response) { double('restclient http response') }

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
            'http://better.place.in/the-world/foo',
            '{"hello":"world"}',
            params: {},
            authorization: 'Basic OkF3ZGhpaGNpVGdPUkdVam5rdWsxdmc9PQ==',
            content_type: :json,
            accept: :json,
            user_agent: 'My Mocking App v1.1'
          ).and_return(mock_response)

          described_class.request_with_body(method, '/foo', {hello: 'world'}, {}, :use_application_token)
        end
      end

      context 'with body as string' do
        it 'should use RestClient.post with the supplied params and common options' do
          RestClient.should_receive(method).with(
            'http://better.place.in/the-world/foo',
            '{"hello":"world"}',
            params: {},
            authorization: 'Basic OkF3ZGhpaGNpVGdPUkdVam5rdWsxdmc9PQ==',
            content_type: :json,
            accept: :json,
            user_agent: 'My Mocking App v1.1'
          ).and_return(mock_response)

          described_class.request_with_body(method, '/foo', '{"hello":"world"}', {}, :use_application_token)
        end
      end
    end
  end

  describe '.request_without_body' do
    %w[].each do |method|
      it "should use RestClient.#{method} with the supplied params and common options" do
        RestClient.should_receive(method).with(
          'http://better.place.in/the-world/foo',
          params: {spam: 'eggs'},
          authorization: 'Basic OkF3ZGhpaGNpVGdPUkdVam5rdWsxdmc9PQ==',
          content_type: :json,
          accept: :json,
          user_agent: 'My Mocking App v1.1'
        ).and_return(mock_response)

        described_class.request_without_body(method, '/foo', spam: 'eggs')
      end
    end
  end

  %w[get delete].each do |method|
    describe ".#{method}"  do
      it 'should delegate to request_without_body' do
        Charging::Http.should_receive(:request_without_body).with(
          method.to_sym,
          '/foo',
          {},
          :use_application_token
        )

        described_class.send(method, '/foo')
      end
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
          :use_application_token
        )

        described_class.send(method, '/foo', 'body', spam: 'eggs')
      end
    end
  end

  specify('.charging_path') do
    expect(described_class.charging_path('/path')).to eql 'http://better.place.in/the-world/path'
  end

  specify('.common_params') do
    expect(described_class.common_params('token')).to eql({
      accept: :json,
      authorization: 'Basic OnRva2Vu',
      content_type: :json,
      user_agent: 'My Mocking App v1.1'
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
end
