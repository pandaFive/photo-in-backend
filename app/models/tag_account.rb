# frozen_string_literal: true

class TagAccount < ApplicationRecord
  belongs_to :tag
  belongs_to :account
end
