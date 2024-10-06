require "rails_helper"

module Automations
  RSpec.describe Container do
    # test_app/app/models/container is an ActiveRecord model with the Automations::Automatable module included

    # standard:disable Lint/ConstantDefinitionInBlock
    class ContainerBeforeTrigger
      def can_call?(automation, **params) = true
    end
    # standard:enable Lint/ConstantDefinitionInBlock

    describe "#automations" do
      before do
        @container = Automatable.create name: "My container"
        @inactive_automation = Automation.create container: @container, name: "Inactive automation", status: "inactive"
        @active_automation = Automation.create container: @container, name: "Active automation", status: "active"
      end

      it "adds a `has_many` relation to the model" do
        expect(@container).to respond_to(:_automations)
      end

      it "lists active automations" do
        @active_automations = @container.active_automations

        expect(@active_automations.size).to eq 1
        expect(@active_automations).to include(@active_automation)
      end

      it "lists inactive automations" do
        @inactive_automations = @container.inactive_automations

        expect(@inactive_automations.size).to eq 1
        expect(@inactive_automations).to include(@inactive_automation)
      end
    end

    describe "#add_automation" do
      it "adds an automation" do
        @schedule = DailySchedule.new days: [1, 2], times: [8, 12]
        @container = Automatable.create name: "My container"

        @automation = @container.add_automation "My scheduled automation", configuration: @schedule

        expect(@automation).to_not be_nil
        expect(@automation).to be_active
        expect(@automation.name).to eq "My scheduled automation"
        expect(@automation.send(:configuration)).to eq @schedule
      end

      it "adds an automation with a before_trigger class" do
        @schedule = DailySchedule.new days: [1, 2], times: [8, 12]
        @container = Automatable.create name: "My container"

        @automation = @container.add_automation "My scheduled automation", configuration: @schedule, before_trigger: ContainerBeforeTrigger

        expect(@automation).to_not be_nil
        expect(@automation.before_trigger).to be_kind_of(ContainerBeforeTrigger)
      end

      it "adds an automation with a before_trigger class name" do
        @schedule = DailySchedule.new days: [1, 2], times: [8, 12]
        @container = Automatable.create name: "My container"

        @automation = @container.add_automation "My scheduled automation", configuration: @schedule, before_trigger: ContainerBeforeTrigger

        expect(@automation).to_not be_nil
        expect(@automation.send(:before_trigger)).to be_kind_of(ContainerBeforeTrigger)
      end
    end

    describe "#call_automations" do
      it "calls the active automations"
    end
  end
end
