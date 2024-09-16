require "rails_helper"

module Automations
  RSpec.describe ScheduledAutomation, type: :model do
    context ".for" do
      it "lists active scheduled automations for the given container" do
        @container = Automatable.create! name: "My container"
        @active_automation = ScheduledAutomation.create! container: @container, name: "Active automation", status: "active"
        @inactive_automation = ScheduledAutomation.create! container: @container, name: "Inactive automation", status: "inactive"
        @other_automation = Trigger.create! container: @container, name: "Other automation", status: "active"

        expect(ScheduledAutomation.for(@container)).to eq([@active_automation])
      end
    end
  end
end
