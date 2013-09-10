# encoding: utf-8

require 'charging/null_object'

describe Charging::NullObject do
  subject { described_class.new(:response) }

  its(:nil?) { should be_true }
  its(:to_a) { should eql [] }
  its(:to_i) { should eql 0 }
  its(:to_f) { should eql 0.0 }
  its(:to_s) { should eql '' }
  its(:last_response) { should eql :response }
end
