require "rails_helper"

module Automations
  RSpec.describe Automation, type: :model do
    # standard:disable Lint/ConstantDefinitionInBlock
    class AreYouReady < Struct.new(:are_you_ready, keyword_init: true)
      def ready?(**params) = are_you_ready
    end

    class BeforeTriggerSaysNo
      def can_call?(automation, **params) = false
    end

    class BeforeTriggerSaysYes
      def can_call?(automation, **params) = true
    end

    class RespondsWithGreeting < Struct.new(:greeting, keyword_init: true)
      def call(**params) = {greeting: "#{greeting} #{params[:name]}"}
    end

    class SwearsLoudly < Struct.new(:expletive, keyword_init: true)
      def call(**params) = {response: expletive.to_s}
    end
    # standard:enable Lint/ConstantDefinitionInBlock

    context ".for" do
      it "lists active automations for the given container" do
        @container = Automatable.create! name: "My container"
        @active_automation = Automation.create! container: @container, name: "Active automation", status: "active"
        @inactive_automation = Automation.create! container: @container, name: "Inactive automation", status: "inactive"

        expect(Automation.for(@container)).to eq([@active_automation])
      end
    end

    context "#to_s" do
      it "returns the automation's name" do
        @automation = Automation.new name: "My automation"
        expect(@automation.to_s).to eq "My automation"
      end
    end

    context "#container" do
      it "is mandatory" do
        @automation = Automation.new container: nil
        expect(@automation).not_to be_valid
        expect(@automation.errors[:container]).to_not be_empty
      end
    end

    context "#name" do
      it "is mandatory" do
        @automation = Automation.new name: ""
        expect(@automation).not_to be_valid
        expect(@automation.errors[:name]).to_not be_empty
      end
    end

    context "#status" do
      it "is either active or inactive" do
        expect { Automation.new status: "something" }.to raise_error ArgumentError
      end
    end

    context "#configuration" do
      it "must have #ready? #to_s and #to_h methods" do
        @bad_config = Object.new

        expect { Automation.new(configuration: @bad_config) }.to raise_error(TypeError)
      end

      it "is stored with the automation" do
        @automation = Automation.new configuration: AreYouReady.new(are_you_ready: true)

        expect(@automation.configuration).to be_kind_of AreYouReady
        expect(@automation.configuration.are_you_ready).to eq true
      end
    end

    context "#before_trigger" do
      it "must have a #can_call? method" do
        @bad_config = Object.new

        expect { Automation.new(before_trigger: @bad_config) }.to raise_error(TypeError)
      end

      it "is stored with the automation" do
        @automation = Automation.new before_trigger: BeforeTriggerSaysNo.new

        expect(@automation.before_trigger).to be_kind_of BeforeTriggerSaysNo
      end
    end

    context "#call" do
      it "does nothing if a before trigger is defined and says the automation cannot be called" do
        @automation = Automation.new configuration: AreYouReady.new(are_you_ready: true), before_trigger: BeforeTriggerSaysNo.new

        expect(Automations::ActionCaller).to_not receive(:new)

        @automation.call(some: "values")
      end

      it "calls its actions if the before trigger says it can be called and the configuration is ready" do
        @automation = Automation.new configuration: AreYouReady.new(are_you_ready: true), before_trigger: BeforeTriggerSaysYes.new

        @action_caller = double "Automations::ActionCaller"
        expect(Automations::ActionCaller).to receive(:new).and_return(@action_caller)
        expect(@action_caller).to receive(:call).with(say: "Hello")

        @automation.call(say: "Hello")
      end

      it "calls its actions if there is no before trigger and the configuration is ready" do
        @automation = Automation.new configuration: AreYouReady.new(are_you_ready: true)

        @action_caller = double "Automations::ActionCaller"
        expect(Automations::ActionCaller).to receive(:new).and_return(@action_caller)
        expect(@action_caller).to receive(:call).with(say: "Hello")

        @automation.call(say: "Hello")
      end

      it "calls its actions if there is no before trigger and no configuration" do
        @automation = Automation.new

        @action_caller = double "Automations::ActionCaller"
        expect(Automations::ActionCaller).to receive(:new).and_return(@action_caller)
        expect(@action_caller).to receive(:call).with(say: "Hello")

        @automation.call(say: "Hello")
      end
    end

    context "#add_action" do
      it "adds an action to the end of the list" do
        @container = Automatable.create! name: "My container"
        @automation = Automation.create! container: @container, name: "Automation", configuration: AreYouReady.new(are_you_ready: true)

        @first_action = @automation.add_action "First action", handler: RespondsWithGreeting.new(greeting: "Hello")
        expect(@first_action).to be_kind_of Action
        expect(@first_action.position).to eq 1
        expect(@first_action.handler_class_name).to eq "Automations::RespondsWithGreeting"
        expect(@first_action.configuration_data).to eq({greeting: "Hello"})
        @second_action = @automation.add_action "Second action", handler: SwearsLoudly.new(expletive: "balls")
        expect(@second_action).to be_kind_of Action
        expect(@second_action.position).to eq 2
        expect(@second_action.handler_class_name).to eq "Automations::SwearsLoudly"
        expect(@second_action.configuration_data).to eq({expletive: "balls"})
      end
    end

    context "#remove_action" do
      it "removes the given action and reorders the other actions" do
        @container = Automatable.create! name: "My container"
        @automation = Automation.create! container: @container, name: "Automation", configuration: AreYouReady.new(are_you_ready: true)

        @first_action = Action.create! automation: @automation, name: "First action", handler: RespondsWithGreeting.new(greeting: "Hello")
        @second_action = Action.create! automation: @automation, name: "Second action", handler: SwearsLoudly.new(expletive: "balls")
        @third_action = Action.create! automation: @automation, name: "Third action", handler: SwearsLoudly.new(expletive: "fanny")
        expect(@automation.actions.reload.size).to eq 3

        @automation.remove_action @second_action

        expect(@automation.actions.reload.size).to eq 2
        expect(@automation.actions.first).to eq @first_action
        expect(@automation.actions.last).to eq @third_action
        expect(@third_action.reload.position).to eq 2
      end
    end

    context "#call_actions" do
      it "uses an Automations::ActionCaller to call the actions in sequence" do
        @actions = (1..3).map { |i| double "Automations::Action" }
        @automation = Automation.new configuration: AreYouReady.new(are_you_ready: true)
        allow(@automation).to receive(:actions).and_return(@actions)

        @action_caller = double "Automations::ActionCaller"

        expect(Automations::ActionCaller).to receive(:new).with(@actions).and_return(@action_caller)
        expect(@action_caller).to receive(:call).with(say: "Hello")

        @automation.send :call_actions, say: "Hello"
      end
    end
  end
end
