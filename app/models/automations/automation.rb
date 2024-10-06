module Automations
  class Automation < ApplicationRecord
    belongs_to :container, polymorphic: true
    validates :name, presence: true
    enum :status, active: 0, inactive: -1
    serialize :configuration_data, type: Hash, coder: YAML, default: {}
    has_many :actions, -> { order :position }, class_name: "Automations::Action", foreign_key: "automation_id", dependent: :destroy

    scope :for, ->(container) { where(container: container).active }

    def to_s = name

    def to_param = "#{id}-#{name}".parameterize

    def call(**)
      can_call_actions?(**) ? call_actions(**) : nil
    end

    def add_action name, handler:
      actions.create! name: name, handler: handler
    end

    def remove_action action
      action.destroy
    end

    def configuration
      configuration_class_name.blank? ? nil : configuration_class_name.constantize.new(**configuration_data.except(:class_name, :before_trigger))
    end

    def configuration= value
      Automations::Configuration.verify value
      self.configuration_class_name = value&.class&.name || ""
      self.configuration_data = value&.to_h || {}
    end

    def before_trigger
      before_trigger_class_name.blank? ? nil : before_trigger_class_name.constantize.new
    end

    def before_trigger= value
      Automations::BeforeTrigger.verify value
      self.before_trigger_class_name = value&.class&.name || ""
    end

    private

    def can_call_actions?(**)
      callback = before_trigger
      return false if callback.present? && !callback.can_call?(self, **)
      configuration.nil? ? true : configuration.ready?(**)
    end

    def call_actions(**) = Automations::ActionCaller.new(actions).call(**)
  end
end
