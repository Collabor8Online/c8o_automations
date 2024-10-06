module Automations
  module Container
    extend ActiveSupport::Concern

    included do
      has_many :_automations, as: :container, class_name: "Automations::Automation", dependent: :destroy
      has_many :active_automations, -> { active }, as: :container, class_name: "Automations::Automation"
      has_many :inactive_automations, -> { inactive }, as: :container, class_name: "Automations::Automation"
    end

    def add_automation name, configuration:, before_trigger: nil
      Automations::Automation.create!(container: self, name: name, status: "active", configuration_data: configuration.to_h, configuration_class_name: configuration.class.name, before_trigger_class_name: before_trigger_class_name_from(before_trigger)).tap do |automation|
        active_automations.reload
      end
    end

    def trigger_automations **params
      active_automations.collect { |automation| automation.call(**params) }
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
