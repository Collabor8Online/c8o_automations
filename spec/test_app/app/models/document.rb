class Document < ApplicationRecord
  belongs_to :folder
  enum :status, {requires_review: 0, reviewed: 1}
  validates :name, presence: true
end
