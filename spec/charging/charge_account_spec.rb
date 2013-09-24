require 'spec_helper'

describe Charging::ChargeAccount do
  context 'for new instance' do
    ATTRIBUTES = [
      :bank, :name, :agreement_code, :portfolio_code, :account, :agency, 
      :default_charging_features, :currency, :supplier_name, :address, 
      :zipcode, :sequence_number, :our_number_range, :advance_days
    ]
    
    let(:domain) { double(:domain) }
    let(:response) { double(:response) }
    
    subject do
      attributes = Hash[*ATTRIBUTES.map {|attr| [attr, "#{attr} value"] }.flatten]
      
      described_class.new(attributes, domain, response)
    end
    
    ATTRIBUTES.each do |attribute|
      its(attribute) { should eq "#{attribute} value"}
    end
    
    [:uuid, :uri, :etag, :national_indentify].each do |attribute|
      its(attribute) { should be_nil }
    end
    
    its(:domain) { should eq domain }
    its(:last_response) { should eq response }
    its(:errors) { should eq [] }
    
    specify('#persisted?') { expect(subject).to_not be_persisted }
    specify('#deleted?') { expect(subject).to_not be_deleted }
    
    its(:attributes) do
      should eq({
        account: 'account value',
        address: 'address value',
        advance_days: "advance_days value",
        agency: "agency value",
        agreement_code: "agreement_code value",
        bank: "bank value",
        currency: "currency value",
        default_charging_features: "default_charging_features value",
        name: "name value",
        our_number_range: "our_number_range value",
        portfolio_code: "portfolio_code value",
        sequence_number: "sequence_number value",
        supplier_name: "supplier_name value",
        zipcode: "zipcode value"
      })
    end
  end
end
