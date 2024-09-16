module Automations
  module Validations
    private

    def validate_times times
      raise ArgumentError.new("Times #{times} are not valid") if times.any? { |time| !time.to_i.between? 0, 23 }
    end

    def validate_days_of_the_week days
      raise ArgumentError.new("Days #{days} are not valid") if days.any? { |day| !day.to_i.between? 0, 6 }
    end

    def validate_days_of_the_month days
      raise ArgumentError.new("Days #{days} are not valid") if days.any? { |day| !day.to_i.between? 1, 31 }
    end

    def validate_weeks weeks
      raise ArgumentError.new("Weeks #{weeks} are not valid") if weeks.any? { |week| !week.to_i.between? 1, 5 }
    end

    def validate_months months
      raise ArgumentError.new("Months #{months} are not valid") if months.any? { |month| !month.to_i.between? 1, 12 }
    end
  end
end
