class Automatable < ApplicationRecord
  include Automations::Container

  has_many :folders, foreign_key: "project_id", dependent: :destroy
  validates :name, presence: true
end
