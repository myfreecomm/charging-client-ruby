# encoding: utf-8
require 'base64'

module Charging
  module Http # :nodoc:
    class LastResponseError < RuntimeError
      attr_reader :last_response

      def initialize(last_response)
        super
        @last_response = last_response
      end

      def message
        last_response.to_s
      end
    end

    module_function

    def get(path, token, params = {})
      request_to_api(:get, path, params, token)
    end

    def delete(path, token, etag)
      request_to_api(:delete, path, {etag: etag}, token)
    end

    def post(path, token, body = {}, params = {})
      request_to_api(:post, path, params, token, body)
    end

    def put(path, token, etag, body = {})
      request_to_api(:put, path, {etag: etag}, token, body)
    end

    def patch(path, token, etag, body = {})
      request_to_api(:patch, path, {etag: etag}, token, body)
    end

    def basic_credential_for(user, password = nil)
      credential_for = user.to_s
      credential_for << ":#{password}" unless password.nil?

      credential = ::Base64.strict_encode64(credential_for)
      "Basic #{credential}"
    end

    def should_follow_redirect(follow = true)
      proc { |response, request, result, &block|
        if follow && [301, 302, 307].include?(response.code)
          response.follow_redirection(request, result, &block)
        else
          response.return!(request, result, &block)
        end
      }
    end
    
    def request_to_api(method, path, params, token, body = nil)
      path = charging_path(path) unless path.start_with?('http')
      etag = params.delete(:etag)
      
      args = [method, path]
      args << encoded_body(body) if body

      RestClient.send(*args,
        {params: params}.merge(common_params(token, etag)),
        &should_follow_redirect
      )
    rescue ::RestClient::Exception => exception
      raise LastResponseError.new(exception.response)
    end

    def charging_path(path)
      "#{Charging.configuration.url}#{path}"
    end

    def common_params(token, etag)
      token = Charging.configuration.application_token if token === :use_application_token
      request_headers = {
        authorization: basic_credential_for('', token),
        content_type: :json,
        accept: :json,
        user_agent: Charging.configuration.user_agent
      }

      request_headers['If-Match'] = etag if etag

      request_headers
    end

    def encoded_body(body)
      body.is_a?(Hash) ? MultiJson.encode(body) : body
    end
  end
end
