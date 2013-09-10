# encoding: utf-8
require 'base64'

module Charging
  module Http # :nodoc:
    module_function

    def get(path, token, params = {})
      request_without_body(:get, path, params, token)
    end

    def delete(path, token, params = {})
      request_without_body(:delete, path, params, token)
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

    def request_with_body(method, path, body, params, token)
      RestClient.send(
        method,
        charging_path(path),
        encoded_body(body),
        {params: params}.merge(common_params(token))
      )
    end

    def request_without_body(method, path, params, token)
      RestClient.send(
        method,
        charging_path(path),
        {params: params}.merge(common_params(token))
      )
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
