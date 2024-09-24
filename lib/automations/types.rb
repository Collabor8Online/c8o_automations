require "plumbing"

module Automations
  Configuration = Plumbing::RubberDuck.define :call, :to_h, :to_s
  Handler = Plumbing::RubberDuck.define :call, :to_h, :to_s
end
