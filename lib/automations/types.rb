require "plumbing"

module Automations
  Configuration = Plumbing::RubberDuck.define :ready?, :to_h, :to_s
  Handler = Plumbing::RubberDuck.define :accepts?, :call, :to_h, :to_s
end
