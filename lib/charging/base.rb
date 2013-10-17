# encoding: UTF-8

module Charging
  class Base
    DEFAULT_PAGE = 1
    DEFAULT_LIMIT = 10

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
    
    def create!(&block)
      execute_and_capture_raises_at_errors(201) do
        @last_response = block.call
      end
      
      self
    end
    
    def destroy!(&block)
      execute_and_capture_raises_at_errors(204) do
        @last_response = block.call
      end
      
      if errors.empty?
        @deleted = true
        @persisted = false
      end
      
      self
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
      raise ArgumentError, "Invalid attributes for #{self.name}: #{attributes.inspect}" if diff.any?
    end
    
    private
    
    def self.raise_last_response_unless(status_code, response)
      raise Http::LastResponseError.new(response) if response.code != status_code
    end
    
    def raise_last_response_unless(status_code)
      self.class.raise_last_response_unless(status_code, last_response)
    end
    
    def execute_and_capture_raises_at_errors(success_code, &block)
      reset_errors!
      
      block.call

      raise_last_response_unless success_code
    ensure
      if $ERROR_INFO
        @last_response = $ERROR_INFO.last_response if $ERROR_INFO.kind_of?(Http::LastResponseError)
        @errors = [$ERROR_INFO.message]
      end
    end
    
    def reset_errors!
      @errors = []
    end

    def get_attributes
      ((self.class::ATTRIBUTES || []) + (self.class::READ_ONLY_ATTRIBUTES || []) + COMMON_ATTRIBUTES).flatten.uniq
    end
  end
end
