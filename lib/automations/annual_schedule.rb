module Automations
  class AnnualSchedule < Struct.new(:months, :days, :times)
    include Plumbing::Pipeline
    include Validations

    pre_condition :time_supplied do |input|
      input.key? :time
    end

    perform :check_time

    def initialize(months:, days:, times:)
      validate_months months
      validate_days_of_the_month days
      validate_times times
      super(months, days, times)
    end

    def to_s = "Annual - M: #{months.inspect}, D: #{days.inspect}, T: #{times.inspect}"
    alias_method :ready?, :call

    private

    def check_time(input)
      time = input[:time]
      months.include?(time.month) && days.include?(time.day) && times.include?(time.hour)
    end
  end
end
