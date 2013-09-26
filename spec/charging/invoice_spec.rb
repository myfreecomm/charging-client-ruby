# encoding: utf-8

require 'spec_helper'

describe Charging::Invoice do
  let(:domain) { double(:domain, token: 'QNTGvpnYRVC4HbHibDBUIQ==') }
  let(:uuid) { '29e77bc5-0e70-444c-a922-3149e78d905b' }

  context 'for new instance' do
    INVOICE_ATTRIBUTES = [ 
      :kind, :amount, :document_number, :drawee, :due_date, 
      :charging_features, :supplier_name, :discount, :interest, :rebate,
      :ticket, :protest_code, :protest_days, :instructions, :demonstrative,
      :our_number
    ]
    
    let(:response) { double(:response) }
    
    subject do
      attributes = Hash[*INVOICE_ATTRIBUTES.map {|attr| [attr, "#{attr} value"] }.flatten]
      
      described_class.new(attributes, domain, response)
    end
    
    INVOICE_ATTRIBUTES.each do |attribute|
      its(attribute) { should eq "#{attribute} value"}
    end
    
    [:uuid, :uri, :etag, :charge_account, :document_date, :paid].each do |attribute|
      its(attribute) { should be_nil }
    end
    
    its(:domain) { should eq domain }
    its(:last_response) { should eq response }
    its(:errors) { should eq [] }
    
    specify('#persisted?') { expect(subject).to_not be_persisted }
    specify('#deleted?') { expect(subject).to_not be_deleted }
    
    its(:attributes) do
      should eq({
        amount: 'amount value',
        kind: 'kind value',
        document_number: 'document_number value',
        drawee: 'drawee value',
        due_date: 'due_date value',
        charging_features: 'charging_features value',
        supplier_name: 'supplier_name value', 
        discount: 'discount value', 
        interest: 'interest value', 
        rebate: 'rebate value', 
        ticket: 'ticket value', 
        protest_code: 'protest_code value', 
        protest_days: 'protest_days value', 
        instructions: 'instructions value', 
        demonstrative: 'demonstrative value', 
        our_number: 'our_number value'
      })
    end
  end
end
