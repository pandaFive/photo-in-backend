class TagAccount < ApplicationRecord
  belongs_to :tag
  belongs_to :account
end
