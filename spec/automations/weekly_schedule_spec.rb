require "rails_helper"

RSpec.describe Automations::WeeklySchedule do
  context "#initialize" do
    it "accepts weeks between 1 and 5" do
      @schedule = Automations::WeeklySchedule.new weeks: [3, 4], days: [1, 2], times: [10, 22]

      expect(@schedule.weeks).to eq([3, 4])
    end

    it "does not accept weeks outside 1 and 5" do
      expect { Automations::WeeklySchedule.new weeks: [-1, 2], days: [1, 2], times: [10, 22] }.to raise_error ArgumentError

      expect { Automations::WeeklySchedule.new weeks: [1, 6], days: [1, 6], times: [10, 22] }.to raise_error ArgumentError
    end

    it "accepts days between 0 and 6" do
      @schedule = Automations::WeeklySchedule.new weeks: [1, 2], days: [1, 2], times: [10, 22]

      expect(@schedule.days).to eq([1, 2])
    end

    it "does not accept days outside 0 and 6" do
      expect { Automations::WeeklySchedule.new weeks: [1, 2], days: [-1, 2], times: [10, 22] }.to raise_error ArgumentError

      expect { Automations::WeeklySchedule.new weeks: [1, 2], days: [1, 7], times: [10, 22] }.to raise_error ArgumentError
    end

    it "accepts times between 0 and 23" do
      @schedule = Automations::WeeklySchedule.new weeks: [1, 2], days: [1, 2], times: [10, 22]

      expect(@schedule.times).to eq([10, 22])
    end

    it "does not accept times outside 0 and 23" do
      expect { Automations::WeeklySchedule.new weeks: [1, 2], days: [1, 2], times: [-1, 22] }.to raise_error ArgumentError

      expect { Automations::WeeklySchedule.new weeks: [1, 2], days: [1, 2], times: [10, 25] }.to raise_error ArgumentError
    end
  end

  context "#call" do
    it "must be supplied with a time" do
      @schedule = Automations::DailySchedule.new days: [5], times: [11]
      expect { @schedule.call(some: "data") }.to raise_error(Plumbing::PreConditionError)
    end

    it "is ready if the week, day and time match" do
      @schedule = Automations::WeeklySchedule.new weeks: [1], days: [5], times: [11]
      Timecop.travel Time.new(2024, 9, 6, 11, 0) do # Friday, 6th September 2024, 11:00, 1st week of the month
        expect(@schedule.call(time: Time.now)).to be true
      end
    end

    it "is ready if the week and day match and the time is within the following hour" do
      @schedule = Automations::WeeklySchedule.new weeks: [1], days: [5], times: [11]
      Timecop.travel Time.new(2024, 9, 6, 11, 45) do # Friday, 6th September 2024, 11:45, 1st week of the month
        expect(@schedule.call(time: Time.now)).to be true
      end
    end

    it "is not ready if the week does not match and the day and time match" do
      @schedule = Automations::WeeklySchedule.new weeks: [3, 4], days: [5], times: [11]
      Timecop.travel Time.new(2024, 9, 6, 11, 45) do # Friday, 6th September 2024, 11:45, 1st week of the month
        expect(@schedule.call(time: Time.now)).to be false
      end
    end

    it "is not ready if the day does not match and the week and time match" do
      @schedule = Automations::WeeklySchedule.new weeks: [1], days: [4], times: [11]
      Timecop.travel Time.new(2024, 9, 6, 11, 0) do # Friday, 6th September 2024, 11:00, 1st week of the month
        expect(@schedule.call(time: Time.now)).to be false
      end
    end

    it "is not ready if the week and day match and the time does not match" do
      @schedule = Automations::WeeklySchedule.new weeks: [1], days: [5], times: [12]
      Timecop.travel Time.new(2024, 9, 6, 11, 0) do # Friday, 6th September 2024, 11:00, 1st week of the month
        expect(@schedule.call(time: Time.now)).to be false
      end
    end
  end

  context "#to_h" do
    it "publishes its attributes" do
      @schedule = Automations::WeeklySchedule.new weeks: [1], days: [5], times: [12]
      expect(@schedule.to_h).to eq({weeks: [1], days: [5], times: [12]})
    end
  end
end
