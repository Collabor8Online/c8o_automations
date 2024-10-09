module Automations
  class Builder
    def initialize yaml, container:
      @yaml = yaml
      @container = container
    end

    def call
      @container.automations.where(name: data["name"]).first_or_initialize.tap do |automation|
        automation.update! configuration_class_name: data["class_name"], configuration_data: data["configuration"]
        automation.actions.destroy_all
        data["actions"].each do |action_data|
          automation.actions.create! name: action_data["name"], handler_class_name: action_data["class_name"], configuration_data: action_data["configuration"].to_h
        end
      end
    end
    alias_method :build_automation, :call

    private

    def data
      @data ||= @yaml.is_a?(Hash) ? @yaml.with_indifferent_access : YAML.load(@yaml)
    end
  end
end
