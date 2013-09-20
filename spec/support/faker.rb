# encoding: utf-8


# Based on https://github.com/bernardo/cpf_faker
module Faker
  module_function

  def cnpj_generator(cnpj_base = nil)
    cnpj_root = cnpj_base.nil? ? Array.new(12) { rand(10) } : cnpj_base.split('').map(&:to_i)

    # calculate first digit
    factor = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]

    sum = (0..11).inject(0) do |sum, i|
      sum + cnpj_root[i] * factor[i]
    end

    first_validator = sum % 11
    cnpj_root << first_validator = first_validator < 2 ? 0 : 11 - first_validator

    # calculate second digit
    factor.unshift 6

    sum = (0..12).inject(0) do |sum, i|
      sum + cnpj_root[i] * factor[i]
    end

    second_validator = sum % 11
    (cnpj_root << second_validator = second_validator < 2 ? 0 : 11 - second_validator).join
  end

  def cpf_generator(cpf_base = nil)

    cpf_root = cpf_base.nil? ? Array.new(9) { rand(10) } : cpf_base.split('').map(&:to_i)

    # calculate first digit
    sum = (0..8).inject(0) do |sum, i|
      sum + cpf_root[i] * (10 - i)
    end

    first_validator = sum % 11
    first_validator = first_validator < 2 ? 0 : 11 - first_validator
    cpf_root << first_validator

    # calculate second digit
    sum = (0..8).inject(0) do |sum, i|
      sum + cpf_root[i] * (11 - i)
    end

    sum += first_validator * 2

    second_validator = sum % 11
    second_validator = second_validator < 2 ? 0 : 11 - second_validator
    (cpf_root << second_validator).join
  end
end
