# encoding: utf-8

module Charging
  # Represents a object collection result. It is a delegator for an array of object.
  class Collection < SimpleDelegator

    # Responds the last http response from the API.
    attr_reader :last_response

    def initialize(response, attributes) # :nodoc:
      Helpers.required_arguments!(attributes.merge('response' => response))

      @last_response = response
      
      attributes.each do |attribute, value|
        instance_variable_set("@#{attribute}", value)
      end
      
      super(load_data_with_response!)
    end

    def load_data_with_response! # :nodoc:
      return [] if last_response.code != 200

      raw_lines = MultiJson.decode(last_response.body)
      raw_lines.map { |raw_line| load_object_with(raw_line) }
    end
  end
end
