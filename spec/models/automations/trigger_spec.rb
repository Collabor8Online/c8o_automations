require "rails_helper"

module Automations
  RSpec.describe Trigger, type: :model do
    context ".for" do
      it "lists active triggers for the given container" do
        @container = Automatable.create! name: "My container"
        @active_automation = Trigger.create! container: @container, name: "Active automation", status: "active"
        @inactive_automation = Trigger.create! container: @container, name: "Inactive automation", status: "inactive"
        @other_automation = ScheduledAutomation.create! container: @container, name: "Other automation", status: "active"

        expect(Trigger.for(@container)).to eq([@active_automation])
      end
    end
  end
end
