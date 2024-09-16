module Automations
  class EventNameFilter < Struct.new(:event_names, keyword_init: true)
    def initialize event_names: []
      super(event_names: event_names.map(&:to_s))
    end

    def ready? event:, data:
      event_names.include? event.to_s
    end

    def to_s
      "Events - #{event_names.inspect}"
    end
  end
end
