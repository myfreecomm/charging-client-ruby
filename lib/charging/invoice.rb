# encoding: utf-8

module Charging
  class Invoice < Base
    ATTRIBUTES = [ 
      :kind, :amount, :document_number, :drawee, :due_date, 
      :charging_features, :supplier_name, :discount, :interest, :rebate,
      :ticket, :protest_code, :protest_days, :instructions, :demonstrative,
      :our_number
    ]
    
    READ_ONLY_ATTRIBUTES = [ :charge_account, :document_date, :paid ]
    
    attr_accessor(*ATTRIBUTES)
    attr_reader(*READ_ONLY_ATTRIBUTES, :domain)
    
    def initialize(attributes, domain, response = nil)
      super(attributes, response)
      @domain = domain
    end
  end
end
