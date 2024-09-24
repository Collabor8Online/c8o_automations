module Automations
  class Automation < ApplicationRecord
    belongs_to :container, polymorphic: true
    validates :name, presence: true
    enum :status, active: 0, inactive: -1
    serialize :configuration_data, type: Hash, coder: YAML, default: {}
    has_many :actions, -> { order :position }, class_name: "Automations::Action", foreign_key: "automation_id", dependent: :destroy

    scope :for, ->(container) { where(container: container).active }
    scope :scheduled, -> { where(type: "Automations::ScheduledAutomation").active }
    scope :triggers, -> { where(type: "Automations::Trigger").active }

    def to_s = name

    def to_param = "#{id}-#{name}".parameterize

    def call **params
      permitted?(**params) ? trigger_actions(**params) : nil
    end

    def add_action name, handler:
      actions.create! name: name, handler: handler
    end

    def configuration
      @configuration ||= configuration_class_name.constantize.new(**configuration_data.except(:class_name, :before_trigger))
    end

    def configuration= value
      Automations::Configuration.verify value
      self.configuration_data = value.to_h
      self.configuration_class_name = value.class.name
    end

    private

    def permitted? **params
      before_trigger.nil? ? true : before_trigger.trigger?(self, **params)
    end

    def before_trigger
      return nil if before_trigger_class_name.blank?
      @before_trigger ||= before_trigger_class_name.constantize.new
    end

    def trigger_actions **params
      results = params
      actions.each do |action|
        next unless action.accepts?(**results)
        results = results.merge action.call(**results)
      end
      results
    end
  end
end
