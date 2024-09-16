module Automations
  class MonthlySchedule < Struct.new(:days, :times)
    include Validations

    def initialize(days:, times:)
      validate_days_of_the_month days
      validate_times times
      super(days, times)
    end

    def ready?(time:, **)
      days.include?(time.day) && times.include?(time.hour)
    end

    def to_s
      "Monthly - D: #{days.inspect}, T: #{times.inspect}"
    end
  end
end
