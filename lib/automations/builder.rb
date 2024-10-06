module Automations
  class Builder
    def initialize yaml, container:
      @yaml = yaml
      @container = container
    end

    def build_automation
      @container.automations.where(name: data["name"]).first_or_initialize.tap do |automation|
        automation.update! configuration_class_name: data["class_name"], configuration_data: data["configuration"]
        automation.actions.destroy_all
        data["actions"].each do |action_data|
          automation.actions.create! name: action_data["name"], handler_class_name: action_data["class_name"], configuration_data: action_data["configuration"]
        end
      end
    end

    private

    def data
      @data ||= YAML.load(@yaml)
    end
  end
end
