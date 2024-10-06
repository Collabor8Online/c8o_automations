module Automations
  def self.events
    @events ||= Plumbing::Pipe.start
  end
end
