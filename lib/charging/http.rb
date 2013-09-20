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
      request_without_body(:get, path, params, token)
    end

    def delete(path, token, params = {})
      request_without_body(:delete, path, params, token, :no_follow)
    end

    def post(path, token, body = {}, params = {})
      request_with_body(:post, path, body, params, token)
    end

    def put(path, token, body = {}, params = {})
      request_with_body(:put, path, body, params, token)
    end

    def patch(path, token, body = {}, params = {})
      request_with_body(:patch, path, body, params, token)
    end

    def basic_credential_for(user, password = nil)
      credential_for = user.to_s
      credential_for << ":#{password}" unless password.nil?

      credential = ::Base64.strict_encode64(credential_for)
      "Basic #{credential}"
    end

    def should_follow_redirect
      proc { |response, request, result, &block|
        if [301, 302, 307].include? response.code
          response.follow_redirection(request, result, &block)
        else
          response.return!(request, result, &block)
        end
      }
    end

    def request_with_body(method, path, body, params, token, follow = true)
      path = charging_path(path) unless path.start_with?('http')

      if follow === :no_follow
        RestClient.send(
          method,
          path,
          encoded_body(body),
          {params: params}.merge(common_params(token))
        )
      else
        RestClient.send(
          method,
          path,
          encoded_body(body),
          {params: params}.merge(common_params(token)),
          &should_follow_redirect
        )
      end
    end

    def request_without_body(method, path, params, token, follow = true)
      path = charging_path(path) unless path.start_with?('http')

      if follow === :no_follow
        RestClient.send(
          method,
          path,
          {params: params}.merge(common_params(token))
        )
      else
        RestClient.send(
          method,
          path,
          {params: params}.merge(common_params(token)),
          &should_follow_redirect
        )
      end
    end

    def charging_path(path)
      "#{Charging.configuration.url}#{path}"
    end

    def common_params(token)
      token = Charging.configuration.application_token if token === :use_application_token
      {
        authorization: basic_credential_for('', token),
        content_type: :json,
        accept: :json,
        user_agent: Charging.configuration.user_agent
      }
    end

    def encoded_body(body)
      body.is_a?(Hash) ? MultiJson.encode(body) : body
    end
  end
end
