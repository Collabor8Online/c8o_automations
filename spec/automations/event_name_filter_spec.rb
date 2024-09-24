require "rails_helper"

RSpec.describe Automations::DailySchedule do
  context "#initialize" do
    it "accepts an array of strings" do
      @filter = Automations::EventNameFilter.new event_names: ["event1", "event2"]

      expect(@filter.event_names).to eq(["event1", "event2"])
    end

    it "converts its data to strings" do
      @filter = Automations::EventNameFilter.new event_names: [:event1, :event2]

      expect(@filter.event_names).to eq(["event1", "event2"])
    end
  end

  context "#call" do
    it "is ready if the event is included" do
      @filter = Automations::EventNameFilter.new event_names: ["event1", "event2"]

      expect(@filter.call(event: "event1", data: "whatever")).to be true
    end

    it "is not ready if the event is not included" do
      @filter = Automations::EventNameFilter.new event_names: ["event1", "event2"]

      expect(@filter.call(event: "HELLO", data: "GOODBYE")).to be false
    end
  end
end
