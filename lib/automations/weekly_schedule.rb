module Automations
  class WeeklySchedule < Struct.new(:weeks, :days, :times)
    include Validations

    def initialize(weeks:, days:, times:)
      validate_weeks weeks
      validate_days_of_the_week days
      validate_times times
      super(weeks, days, times)
    end

    def ready?(time:, **)
      weeks.include?(time.week_of_month) && days.include?(time.wday) && times.include?(time.hour)
    end

    def to_s
      "Weekly - W: #{weeks.inspect}, D: #{days.inspect}, T: #{times.inspect}"
    end
  end
end
