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
      Automations.events.notify "automations/action_fired", action: self, **params
      params.merge handler.call(container: container, automation: automation, action: self, **params)
    rescue => ex
      Automations.events.notify "automations/action_failed", action: self, error_type: ex.class.to_s, error_message: ex.message
      raise ex
    end

    def handler = handler_class_name.constantize.new(**configuration_data)

    def handler= value
      Automations::Handler.verify value
      self.handler_class_name = value&.class&.name || ""
      self.configuration_data = value&.to_h || {}
    end

    def to_configuration_hash
      {"name" => name, "class_name" => handler_class_name, "configuration" => configuration_data}
    end
  end
end
