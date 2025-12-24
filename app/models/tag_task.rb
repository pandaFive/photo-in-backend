# frozen_string_literal: true

class TagTask < ApplicationRecord
  belongs_to :tag
  belongs_to :task
end
