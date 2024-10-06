module Automations
  def self.events
    @events ||= Plumbing::Pipe.start
  end

  def self.reset
    @events = nil
  end
end
