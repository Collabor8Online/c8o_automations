require "rails_helper"

module Automations
  RSpec.describe Container do
    # test_app/app/models/container is an ActiveRecord model with the AutomationsAutomatable module included

    # standard:disable Lint/ConstantDefinitionInBlock
    class ContainerBeforeTrigger
      def can_call?(automation, **params) = true
    end
    # standard:enable Lint/ConstantDefinitionInBlock

    context "#automations" do
      before do
        @container = Automatable.create name: "My container"
        @inactive_automation = ScheduledAutomation.create container: @container, name: "Inactive scheduled automation", status: "inactive"
        @active_automation = ScheduledAutomation.create container: @container, name: "Active scheduled automation", status: "active"
        @inactive_trigger = Trigger.create container: @container, name: "Inactive trigger", status: "inactive"
        @active_trigger = Trigger.create container: @container, name: "Active trigger", status: "active"
      end

      it "adds a `has_many` relation to the model" do
        expect(@container).to respond_to(:_automations)
      end

      it "lists active automations" do
        @active_automations = @container.active_automations

        expect(@active_automations.size).to eq 2
        expect(@active_automations).to include(@active_automation)
        expect(@active_automations).to include(@active_trigger)
      end

      it "lists inactive automations" do
        @inactive_automations = @container.inactive_automations

        expect(@inactive_automations.size).to eq 2
        expect(@inactive_automations).to include(@inactive_automation)
        expect(@inactive_automations).to include(@inactive_trigger)
      end

      it "lists scheduled automations" do
        @scheduled_automations = @container.scheduled_automations

        expect(@scheduled_automations.size).to eq 1
        expect(@scheduled_automations).to include(@active_automation)
      end

      it "lists triggers" do
        @triggers = @container.triggers

        expect(@triggers.size).to eq 1
        expect(@triggers).to include(@active_trigger)
      end
    end

    context "#add_scheduled_automation" do
      it "adds a scheduled automation" do
        @schedule = DailySchedule.new days: [1, 2], times: [8, 12]
        @container = Automatable.create name: "My container"

        @automation = @container.add_scheduled_automation "My scheduled automation", configuration: @schedule

        expect(@automation).to_not be_nil
        expect(@automation).to be_active
        expect(@automation.name).to eq "My scheduled automation"
        expect(@automation.send(:configuration)).to eq @schedule
      end

      it "adds a scheduled automation with a before_trigger class" do
        @schedule = DailySchedule.new days: [1, 2], times: [8, 12]
        @container = Automatable.create name: "My container"

        @automation = @container.add_scheduled_automation "My scheduled automation", configuration: @schedule, before_trigger: ContainerBeforeTrigger

        expect(@automation).to_not be_nil
        expect(@automation.before_trigger).to be_kind_of(ContainerBeforeTrigger)
      end

      it "adds a scheduled automation with a before_trigger class name" do
        @schedule = DailySchedule.new days: [1, 2], times: [8, 12]
        @container = Automatable.create name: "My container"

        @automation = @container.add_scheduled_automation "My scheduled automation", configuration: @schedule, before_trigger: ContainerBeforeTrigger

        expect(@automation).to_not be_nil
        expect(@automation.send(:before_trigger)).to be_kind_of(ContainerBeforeTrigger)
      end
    end

    context "#add_trigger" do
      it "adds a trigger" do
        @filter = EventNameFilter.new event_names: ["something_updated", "something_created"]
        @container = Automatable.create name: "My container"

        @automation = @container.add_trigger "My trigger", configuration: @filter

        expect(@automation).to_not be_nil
        expect(@automation).to be_active
        expect(@automation.name).to eq "My trigger"
        expect(@automation.send(:configuration)).to eq @filter
      end

      it "adds a trigger with a before_trigger class" do
        @filter = EventNameFilter.new event_names: ["something_updated", "something_created"]
        @container = Automatable.create name: "My container"

        @automation = @container.add_trigger "My trigger", configuration: @filter, before_trigger: ContainerBeforeTrigger

        expect(@automation).to_not be_nil
        expect(@automation.send(:before_trigger)).to be_kind_of(ContainerBeforeTrigger)
      end

      it "adds a trigger with a before_trigger class name" do
        @filter = EventNameFilter.new event_names: ["something_updated", "something_created"]
        @container = Automatable.create name: "My container"

        @automation = @container.add_trigger "My trigger", configuration: @filter, before_trigger: ContainerBeforeTrigger

        expect(@automation).to_not be_nil
        expect(@automation.send(:before_trigger)).to be_kind_of(ContainerBeforeTrigger)
      end
    end

    context "#call_automations_at" do
      it "calls the active scheduled automations" do
        # have to mock this because of active record reloading objects
        Timecop.freeze do
          @time = Time.now
          @automations = [double("automation1"), double("automation2")]
          @container = Automatable.new name: "My container"
          allow(@container).to receive(:scheduled_automations).and_return(@automations)

          @automations.each do |automation|
            expect(automation).to receive(:call).with(time: @time)
          end

          @container.call_automations_at @time
        end
      end
    end

    context "#call_triggers_for" do
      it "calls the active triggers for this container" do
        # have to mock this because of active record reloading objects
        @activity = double("activity")
        @automations = [double("automation1"), double("automation2")]
        @container = Automatable.new name: "My container"
        allow(@container).to receive(:triggers).and_return(@automations)

        @automations.each do |automation|
          expect(automation).to receive(:call).with(event: "some_event", data: @activity)
        end

        @container.call_triggers event: "some_event", data: @activity
      end
    end
  end
end
