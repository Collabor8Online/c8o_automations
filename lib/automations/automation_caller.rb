module Automations
  class AutomationCaller
    def initialize automations
      @automations = automations
    end

    def call **params
      @automations.collect do |automation|
        automation.call(**params)
      rescue => ex
        ex
      end
    end
  end
end
