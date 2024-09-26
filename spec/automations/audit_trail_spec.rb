require "rails_helper"

RSpec.describe "writing to the audit trail" do
  it "records an event when an automation has been triggered"
  it "does not record an event if an automation was not triggered"
  it "records a nested event when an action fire"
  it "records a nested event if an action does not fire"
end
