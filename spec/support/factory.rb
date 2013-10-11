# encoding: utf-8

module Factory
  module_function
  
  def domain_attributes(national_identifier)
    {
      supplier_name: 'Springfield Elemenary School',
      address: '1608 Florida Avenue',
      city_state: 'Greenwood/SC',
      zipcode: '29646',
      national_identifier: national_identifier,
      description: 'The mission of Greenwood School District 50 is to educate all students to become responsible and productive citizens.',
    }
  end
  
  def charge_account_attributes
    {
      bank: '237',
      name: 'Conta de cobrança',
      agreement_code: '12345',
      portfolio_code: '25',
      account: {number: '12345', digit: '6'},
      agency: {number: '12345', digit: '6'},
      currency: 9
    }
  end
  
  def create_resource(klass, parent, attributes)
    klass.new(attributes, parent).create!
  end
end
