# encoding: UTF-8

module Charging
  class Base
    COMMON_ATTRIBUTES = [:uuid, :uri, :etag]
    
    attr_reader :last_response, :errors
    attr_reader(*COMMON_ATTRIBUTES)

    def initialize(attributes, response)
      Helpers.load_variables(self, get_attributes, attributes)
      
      @last_response = response
      @errors = []
      @deleted = false
      
      normalize_etag!
    end
    
    def normalize_etag!
      if @etag.nil?
        @etag = last_response.headers[:etag] if last_response && last_response.code === 200
      else
        @etag = @etag.inspect
      end
    end
    
    # Returns true if the object exists on Charging service.
    def persisted?
      (uuid && etag && uri && !deleted?) || false
    end
    
    # Returns true if the object exists on Charging service.
    def unpersisted?
      !persisted?
    end

    # Returns true if object already deleted on API
    def deleted?
      @deleted || false
    end

    # Returns a hash with attributes
    def attributes
      Helpers.hashify(self, self.class::ATTRIBUTES)
    end
    
    def self.validate_attributes!(attributes) # :nodoc:
      keys = attributes.keys.map(&:to_sym)
      diff = keys - (const_get(:ATTRIBUTES) + const_get(:READ_ONLY_ATTRIBUTES) + COMMON_ATTRIBUTES)
      raise ArgumentError, "Invalid attributes for domain: #{attributes.inspect}" if diff.any?
    end
    
    private
    
    def get_attributes
      ((self.class::ATTRIBUTES || []) + (self.class::READ_ONLY_ATTRIBUTES || []) + COMMON_ATTRIBUTES).flatten.uniq
    end
  end
end
