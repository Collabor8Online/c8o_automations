require "rails_helper"

module Automations
  RSpec.describe Action, type: :model do
    # standard:disable Lint/ConstantDefinitionInBlock
    class SomeHandler < Struct.new(:data, keyword_init: true)
      include Plumbing::Pipeline

      perform :do_something

      private

      def do_something(input)
        (data == "raise_error") ? raise("BOOM") : {data: data}
      end
    end
    # standard:enable Lint/ConstantDefinitionInBlock

    context "#name" do
      it "is mandatory" do
        @action = Action.new name: ""

        expect(@action).to_not be_valid
        expect(@action.errors[:name]).to_not be_empty
      end

      it "is used for #to_s" do
        @action = Action.new name: "My action"

        expect(@action.to_s).to eq "My action"
      end
    end

    context "#configuration_data" do
      it "is a Hash" do
        @action = Action.new
        expect(@action.configuration_data).to eq({})
      end
    end

    context "#handler" do
      it "is created from the handler's class name" do
        @action = Action.new handler_class_name: "Automations::SomeHandler", configuration_data: {data: "something"}

        expect(@action.handler).to be_kind_of Automations::SomeHandler
        expect(@action.handler.data).to eq "something"
      end

      it "can be updated" do
        @action = Action.new handler_class_name: "Automations::SomeHandler", configuration_data: {data: "something"}

        @new_handler = Automations::SomeHandler.new(data: "something_else")

        @action.update handler: @new_handler

        expect(@action.handler_class_name).to eq "Automations::SomeHandler"
        expect(@action.configuration_data).to eq({data: "something_else"})
      end

      it "does not allow handlers to be saved if they do not respond to #call, #to_s and #to_h" do
        @bad_handler = Object.new

        expect { Action.new handler: @bad_handler }.to raise_error TypeError
      end
    end

    context "#call" do
      it "merges the input with the result from the handler" do
        @handler = SomeHandler.new(data: "result")
        @container = Automatable.new
        @automation = Automation.new container: @container
        @action = Action.new automation: @automation, handler: @handler

        expect(@action.call(key: "value")).to eq({key: "value", data: "result"})
      end
    end
  end
end
