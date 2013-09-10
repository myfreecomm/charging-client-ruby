# encoding: utf-8

module Charging
  class NullObject
    attr_reader :last_response

    def initialize(response)
      @last_response = response
    end

    def nil?
      true
    end

    def to_s
      ""
    end

    def to_a
      []
    end

    def to_f
      0.0
    end

    def to_i
      0
    end
  end
end
