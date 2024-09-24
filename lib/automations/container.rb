module Automations
  module Container
    extend ActiveSupport::Concern

    included do
      has_many :_automations, as: :container, class_name: "Automations::Automation", dependent: :destroy
      has_many :active_automations, -> { active }, as: :container, class_name: "Automations::Automation"
      has_many :inactive_automations, -> { inactive }, as: :container, class_name: "Automations::Automation"
      has_many :scheduled_automations, -> { active.scheduled }, as: :container, class_name: "Automations::Automation"
      has_many :triggers, -> { active.triggers }, as: :container, class_name: "Automations::Automation"
    end

    def add_scheduled_automation name, configuration:, before_trigger: nil
      Automations::ScheduledAutomation.create!(container: self, name: name, status: "active", configuration_data: configuration.to_h, configuration_class_name: configuration.class.name, before_trigger_class_name: before_trigger_class_name_from(before_trigger)).tap do |automation|
        scheduled_automations.reload
      end
    end

    def add_trigger name, configuration:, before_trigger: nil
      Automations::Trigger.create!(container: self, name: name, status: "active", configuration_data: configuration.to_h, configuration_class_name: configuration.class.name, before_trigger_class_name: before_trigger_class_name_from(before_trigger)).tap do |trigger|
        triggers.reload
      end
    end

    def call_automations_at time
      scheduled_automations.collect { |automation| automation.call(time: time) }
    end

    def call_triggers **params
      triggers.collect { |trigger| trigger.call(**params) }
    end

    private

    def before_trigger_class_name_from before_trigger
      case before_trigger
      when String then before_trigger
      when Class then before_trigger.name
      else ""
      end
    end
  end
end
