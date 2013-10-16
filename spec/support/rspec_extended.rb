module RSpec
  module Core
    class ExampleGroup
      class << self
        define_example_method :xits,      :pending => 'Temporarily disabled with xits'
      end
    end
  end
end