module Automations
  class AnnualSchedule < Struct.new(:months, :days, :times)
    include Validations

    def initialize(months:, days:, times:)
      validate_months months
      validate_days_of_the_month days
      validate_times times
      super(months, days, times)
    end

    def ready?(time:, **)
      months.include?(time.month) && days.include?(time.day) && times.include?(time.hour)
    end

    def to_s
      "Annual - M: #{months.inspect}, D: #{days.inspect}, T: #{times.inspect}"
    end
  end
end
