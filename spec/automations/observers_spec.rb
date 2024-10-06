require "rails_helper"
require "plumbing/spec/modes"

RSpec.describe "notifiying observers" do
  Plumbing::Spec.modes.each do
    context "Working #{Plumbing.config.mode}" do
      describe "Automations.events" do
        it "allows observers to be added as blocks" do
          @observer = await do
            Automations.events.add_observer { |event_name, data| puts event_name }
          end

          @result = await { Automations.events.is_observer?(@observer) }
          expect(@result).to eq true
        end

        it "allows observers to be added as procs" do
          @observer = ->(event_name, data) { puts event_name }
          await { Automations.events.add_observer @observer }

          @result = await { Automations.events.is_observer?(@observer) }
          expect(@result).to eq true
        end

        it "allows observers to be removed" do
          @observer = ->(event_name, data) { puts event_name }

          Automations.events.add_observer @observer
          Automations.events.remove_observer @observer

          @result = await { Automations.events.is_observer?(@observer) }
          expect(@result).to eq false
        end
      end

      it "notifies observers when an automation has been triggered"
      it "does not notify observers if an automation was not triggered"
      it "notifies observers when an action fire"
      it "notifies observers if an action does not fire"
    end
  end
end
