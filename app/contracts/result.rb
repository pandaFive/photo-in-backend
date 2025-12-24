# frozen_string_literal: true

module Contracts
  Result = Struct.new(:success?, :value, :errors, keyword_init: true)
end
