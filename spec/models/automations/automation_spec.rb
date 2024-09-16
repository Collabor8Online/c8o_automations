require "rails_helper"

module Automations
  RSpec.describe Automation, type: :model do
    # standard:disable Lint/ConstantDefinitionInBlock
    class SomeStruct < Struct.new(:this, :that, keyword_init: true)
    end

    class Configuration < Struct.new(:are_you_ready, keyword_init: true)
      def ready?(**params)
        are_you_ready
      end
    end

    class BeforeTriggerSaysNo
      def trigger?(automation, **params) = false
    end

    class BeforeTriggerSaysYes
      def trigger?(automation, **params) = true
    end

    class RespondsWithGreeting < Struct.new(:greeting, keyword_init: true)
      def accepts?(**params) = true

      def call(**params) = {greeting: "#{greeting} #{params[:name]}"}
    end

    class SwearsLoudly < Struct.new(:expletive, keyword_init: true)
      def accepts?(**params) = true

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

    context "#configuration_data" do
      it "is a hash" do
        @automation = Automation.new configuration_data: {key: "value"}

        expect(@automation.configuration_data).to eq({key: "value"})
      end
    end

    context "#configuration" do
      it "is built from the configuration data's class name and supplied configuration data" do
        @automation = Automation.new configuration_data: {this: "this", that: "that"}, configuration_class_name: "Automations::SomeStruct"

        expect(@automation.configuration).to be_a(Automations::SomeStruct)
        expect(@automation.configuration.this).to eq "this"
        expect(@automation.configuration.that).to eq "that"
      end
    end

    context "#configuration=" do
      it "records the details of the configuration" do
        @automation = Automation.new configuration: Automations::SomeStruct.new(this: "this", that: "that")

        expect(@automation.configuration).to eq Automations::SomeStruct.new(this: "this", that: "that")
      end
    end

    context "#before_trigger" do
      it "is built from the before trigger class name" do
        @automation = Automation.new configuration_data: {this: "this", that: "that"}, configuration_class_name: "Automations::SomeStruct", before_trigger_class_name: "SomeStruct"

        expect(@automation.configuration).to be_a(SomeStruct)
        expect(@automation.configuration.this).to eq "this"
        expect(@automation.configuration.that).to eq "that"
      end
    end

    context "#call" do
      it "does nothing if the configuration is not ready to trigger" do
        @automation = Automation.new configuration_class_name: "Automations::Configuration", configuration_data: {are_you_ready: false}
        expect(@automation).to_not receive(:trigger_actions)

        expect(@automation.call(some: "values")).to be_nil
      end

      it "does nothing if a before_trigger is defined and returns false" do
        @automation = Automation.new configuration_class_name: "Automations::Configuration", before_trigger_class_name: "Automations::BeforeTriggerSaysNo", configuration_data: {are_you_ready: true}

        expect(@automation).to_not receive(:trigger_actions)

        expect(@automation.call(some: "values")).to be_nil
      end

      it "triggers actions if the configuration says it is ready" do
        @automation = Automation.new configuration_class_name: "Automations::Configuration", configuration_data: {are_you_ready: true}

        expect(@automation).to receive(:trigger_actions).with(say: "Hello").and_return({greeting: "Hello Alice"})
        expect(@automation.call(say: "Hello")).to eq({greeting: "Hello Alice"})
      end

      it "triggers actions if the configuration says it is ready and the before_trigger hook returns true" do
        @automation = Automation.new configuration_class_name: "Automations::Configuration", before_trigger_class_name: "Automations::BeforeTriggerSaysYes", configuration_data: {are_you_ready: true}

        expect(@automation).to receive(:trigger_actions).with(say: "Hello").and_return({greeting: "Hello Alice"})
        expect(@automation.call(say: "Hello")).to eq({greeting: "Hello Alice"})
      end
    end

    context "#trigger_actions" do
      it "triggers the actions" do
        @first = double("Action", accepts?: true)
        @second = double("Action", accepts?: true)

        @automation = Automation.new configuration_class_name: "Automations::Configuration", configuration_data: {are_you_ready: true}
        allow(@automation).to receive(:actions).and_return [@first, @second]

        expect(@first).to receive(:call).with(some: "params").and_return(some: "params")
        expect(@second).to receive(:call).with(some: "params").and_return(some: "params")

        @automation.send :trigger_actions, some: "params"
      end

      it "ignores actions that do not accept the input parameters" do
        @first = double("Action", accepts?: true)
        @second = double("Action", accepts?: false)

        @automation = Automation.new configuration_class_name: "Automations::Configuration", configuration_data: {are_you_ready: true}
        allow(@automation).to receive(:actions).and_return [@first, @second]

        expect(@first).to receive(:call).with(some: "params").and_return(some: "params")
        expect(@second).to_not receive(:call)

        @automation.send :trigger_actions, some: "params"
      end

      it "combines the results of the actions" do
        @first = double("Action", accepts?: true)
        @second = double("Action", accepts?: true)

        @automation = Automation.new configuration_class_name: "Automations::Configuration", configuration_data: {are_you_ready: true}
        allow(@automation).to receive(:actions).and_return [@first, @second]

        expect(@first).to receive(:call).with(some: "params").and_return(extra: "data")
        expect(@second).to receive(:call).with(some: "params", extra: "data").and_return(some: "override")

        @automation.send :trigger_actions, some: "params"
      end

      it "returns the combined results of all actions" do
        @first = double("Action", accepts?: true)
        @second = double("Action", accepts?: true)

        @automation = Automation.new configuration_class_name: "Automations::Configuration", configuration_data: {are_you_ready: true}
        allow(@automation).to receive(:actions).and_return [@first, @second]

        allow(@first).to receive(:call).with(some: "params").and_return(extra: "data")
        allow(@second).to receive(:call).with(some: "params", extra: "data").and_return(some: "override")

        expect(@automation.send(:trigger_actions, some: "params")).to eq({some: "override", extra: "data"})
      end
    end

    context "#add_action" do
      it "adds an action to the end of the list" do
        @container = Automatable.create! name: "My container"
        @automation = Automation.create! container: @container, name: "Automation", configuration_class_name: "Automations::Configuration", configuration_data: {are_you_ready: true}

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
  end
end
