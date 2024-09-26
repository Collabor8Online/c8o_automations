require "rails_helper"

RSpec.describe Automations::ActionCaller do
  context "with one action" do
    it "merges the incoming parameters with the results of the action" do
      @action = double "action"
      allow(@action).to receive(:call).and_return({first: "action"})

      @result = Automations::ActionCaller.new([@action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", first: "action", success: true})
    end

    it "returns success == false if the first action raises an exception" do
      @action = double "action"
      allow(@action).to receive(:call).and_raise(RuntimeError.new("BANG"))

      @result = Automations::ActionCaller.new([@action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", success: false, error_type: "RuntimeError", error_message: "BANG"})
    end
  end

  context "with two actions" do
    it "merges the incoming parameters with the results of each action" do
      @first_action = double "action"
      allow(@first_action).to receive(:call).and_return({first: "action"})
      @second_action = double "action"
      allow(@second_action).to receive(:call).and_return({second: "result"})

      @result = Automations::ActionCaller.new([@first_action, @second_action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", first: "action", second: "result", success: true})
    end

    it "returns success == false if the first action raises an exception" do
      @first_action = double "action"
      allow(@first_action).to receive(:call).and_raise(RuntimeError.new("BANG"))
      @second_action = double "action"
      allow(@second_action).to receive(:call).and_return({second: "result"})

      @result = Automations::ActionCaller.new([@first_action, @second_action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", success: false, error_type: "RuntimeError", error_message: "BANG"})
    end

    it "returns success == false if the second action raises an exception" do
      @first_action = double "action"
      allow(@first_action).to receive(:call).and_return({first: "action"})
      @second_action = double "action"
      allow(@second_action).to receive(:call).and_raise(RuntimeError.new("BANG"))

      @result = Automations::ActionCaller.new([@first_action, @second_action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", first: "action", success: false, error_type: "RuntimeError", error_message: "BANG"})
    end
  end

  context "with three actions" do
    it "merges the incoming parameters with the results of each action" do
      @first_action = double "action"
      allow(@first_action).to receive(:call).and_return({first: "action"})
      @second_action = double "action"
      allow(@second_action).to receive(:call).and_return({second: "result"})
      @third_action = double "action"
      allow(@third_action).to receive(:call).and_return({third: 999})

      @result = Automations::ActionCaller.new([@first_action, @second_action, @third_action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", first: "action", second: "result", third: 999, success: true})
    end

    it "returns success == false if the first action raises an exception" do
      @first_action = double "action"
      allow(@first_action).to receive(:call).and_raise(RuntimeError.new("BANG"))
      @second_action = double "action"
      allow(@second_action).to receive(:call).and_return({second: "result"})
      @third_action = double "action"
      allow(@third_action).to receive(:call).and_return({third: 999})

      @result = Automations::ActionCaller.new([@first_action, @second_action, @third_action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", success: false, error_type: "RuntimeError", error_message: "BANG"})
    end

    it "returns success == false if the second action raises an exception" do
      @first_action = double "action"
      allow(@first_action).to receive(:call).and_return({first: "action"})
      @second_action = double "action"
      allow(@second_action).to receive(:call).and_raise(RuntimeError.new("BANG"))
      @third_action = double "action"
      allow(@third_action).to receive(:call).and_return({third: 999})

      @result = Automations::ActionCaller.new([@first_action, @second_action, @third_action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", first: "action", success: false, error_type: "RuntimeError", error_message: "BANG"})
    end

    it "returns success == false if the third action raises an exception" do
      @first_action = double "action"
      allow(@first_action).to receive(:call).and_return({first: "action"})
      @second_action = double "action"
      allow(@second_action).to receive(:call).and_return({second: "result"})
      @third_action = double "action"
      allow(@third_action).to receive(:call).and_raise(RuntimeError.new("BANG"))

      @result = Automations::ActionCaller.new([@first_action, @second_action, @third_action]).call(supplied: "data")
      expect(@result).to eq({supplied: "data", first: "action", second: "result", success: false, error_type: "RuntimeError", error_message: "BANG"})
    end
  end
end
