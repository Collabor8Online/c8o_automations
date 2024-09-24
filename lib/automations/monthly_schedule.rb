module Automations
  class MonthlySchedule < Struct.new(:days, :times)
    include Plumbing::Pipeline
    include Validations

    pre_condition :time_supplied do |input|
      input.key? :time
    end

    perform :check_time

    def initialize(days:, times:)
      validate_days_of_the_month days
      validate_times times
      super(days, times)
    end

    def to_s
      "Monthly - D: #{days.inspect}, T: #{times.inspect}"
    end

    private

    def check_time(input)
      time = input[:time]
      days.include?(time.day) && times.include?(time.hour)
    end
  end
end
