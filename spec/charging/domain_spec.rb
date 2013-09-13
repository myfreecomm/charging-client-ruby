# encoding: utf-8

require 'spec_helper'

describe Charging::Domain do
  context 'for new instance' do
    subject do
      described_class.new({
        supplier_name: 'ACME Inc',
        address: '123, Anonymous Stree',
        city_state: 'Neverland',
        zipcode: '12345-678',
        national_identifier: '',
        description: 'Here is a description of ACME Inc'
      })
    end

    its(:supplier_name) { should eq 'ACME Inc' }
    its(:address) { should eq '123, Anonymous Stree' }
    its(:city_state) { should eq  'Neverland' }
    its(:zipcode) { should eq  '12345-678' }
    its(:national_identifier) { should eq  '' }
    its(:description) { should eq  'Here is a description of ACME Inc' }

    its(:uuid) { should be_nil }
    its(:etag) { should be_nil }
    its(:persisted?) { should be_false }
    its(:new_record?) { should be_true }
    its(:last_response) { should be_nil}
  end
end
