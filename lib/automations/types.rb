require "plumbing"

module Automations
  Configuration = Plumbing::RubberDuck.define :ready?, :to_h, :to_s
  BeforeTrigger = Plumbing::RubberDuck.define :can_call?
  Handler = Plumbing::RubberDuck.define :call, :to_h, :to_s
end
