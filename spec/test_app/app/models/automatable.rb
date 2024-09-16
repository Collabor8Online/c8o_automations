class Automatable < ApplicationRecord
  include Automations::Container
  validates :name, presence: true
end
