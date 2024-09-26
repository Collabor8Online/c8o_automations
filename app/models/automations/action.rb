require "acts_as_list"

module Automations
  class Action < ApplicationRecord
    belongs_to :automation, class_name: "Automations::Automation"
    validates :name, presence: true
    acts_as_list scope: :automation
    serialize :configuration_data, type: Hash, coder: YAML, default: {}

    def to_s = name

    def to_param = "#{id}-#{name}".parameterize

    def container = automation.container

    def call **params
      params.merge handler.call(container: container, automation: automation, action: self, **params)
    end

    def handler = handler_class_name.constantize.new(**configuration_data)

    def handler= value
      Automations::Handler.verify value
      self.handler_class_name = value&.class&.name || ""
      self.configuration_data = value&.to_h || {}
    end
  end
end
