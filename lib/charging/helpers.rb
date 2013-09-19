# encoding: utf-8
module Charging
  module Helpers
    module_function
    def load_variables(object, attributes, hash)
      attributes.each do |attribute|
        value = hash.fetch(attribute, hash.fetch(attribute.to_s, nil))
        object.instance_variable_set "@#{attribute}", value
      end
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
