module Automations
  class DailySchedule < Struct.new(:days, :times)
    include Validations

    def initialize(days:, times:)
      validate_days_of_the_week days
      validate_times times
      super(days, times)
    end

    def ready?(time:, **)
      days.include?(time.wday) && times.include?(time.hour)
    end

    def to_s
      "Daily - D: #{days.inspect}, T: #{times.inspect}"
    end
  end
end
