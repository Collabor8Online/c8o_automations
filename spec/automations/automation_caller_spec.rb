require "rails_helper"

RSpec.describe Automations::AutomationCaller do
  subject(:automation_caller) { Automations::AutomationCaller.new([first_automation, second_automation]) }
  let(:first_automation) { double "automation" }
  let(:second_automation) { double "automation" }

  it "calls all the supplied automations with the provided parameters" do
    expect(first_automation).to receive(:call).with(some: "parameters").and_return(more: "data")
    expect(second_automation).to receive(:call).with(some: "parameters").and_return(different: "data")

    automation_caller.call some: "parameters"
  end

  it "ignores any exceptions raised and calls the other automations" do
    expect(first_automation).to receive(:call).with(some: "parameters").and_raise(RuntimeError)
    expect(second_automation).to receive(:call).with(some: "parameters").and_return(different: "data")

    automation_caller.call some: "parameters"
  end
end
