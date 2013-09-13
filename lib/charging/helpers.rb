# encoding: utf-8
require 'uri'

module Charging
  module Helpers
    module_function

    def urify(path, params = {})
      query_params = params.any? ? "?#{URI.encode_www_form(params)}" : ''

      "#{path}#{query_params}"
    end

    def load_variables(object, attributes, hash)
      attributes.each do |attribute|
        value = hash.fetch(attribute, hash.fetch(attribute.to_s, nil))
        object.instance_variable_set "@#{attribute}", value
      end
    end

    def coalesce_int(value, default_value)
      return default_value if value.to_i < 1
      value
    end

    def required_arguments!(arguments)
      errors = []

      arguments.each do |key, value|
        errors << "#{key} required" if value.nil?
      end

      raise ArgumentError, errors.join(', ') if errors.any?
    end
  end
end
