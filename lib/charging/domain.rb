# encoding: utf-8

module Charging
  class Domain
    ATTRIBUTES = [
      :supplier_name,
      :address,
      :city_state,
      :zipcode,
      :national_identifier,
      :description
    ]

    attr_accessor *ATTRIBUTES
    attr_accessor :uuid, :etag, :account, :last_response

    def initialize(attributes)
      Helpers.load_variables(self, ATTRIBUTES, attributes)

      @persisted = false
    end

    def persisted?
      @persisted
    end

    def new_record?
      !persisted?
    end
  end
end
