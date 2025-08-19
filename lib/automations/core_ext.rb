module Automations
  ::Integer.class_eval do
    def to_hour
      "#{to_s.rjust(2, "0")}:00"
    end
  end

  ::Time.class_eval do
    def week_of_month
      (day / 7) + 1
    end
  end
end
