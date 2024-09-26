require "rails_helper"

RSpec.describe Automations::AnnualSchedule do
  context "#initialize" do
    it "accepts months between 1 and 12" do
      @schedule = Automations::AnnualSchedule.new months: [1, 12], days: [1, 2], times: [10, 22]

      expect(@schedule.days).to eq([1, 2])
    end

    it "does not accept months outside 1 and 12" do
      expect { Automations::AnnualSchedule.new months: [0, 12], days: [1, 2], times: [10, 22] }.to raise_error ArgumentError

      expect { Automations::AnnualSchedule.new months: [1, 13], days: [1, 3], times: [10, 22] }.to raise_error ArgumentError
    end

    it "accepts days between 1 and 31" do
      @schedule = Automations::AnnualSchedule.new months: [1, 12], days: [1, 2], times: [10, 22]

      expect(@schedule.days).to eq([1, 2])
    end

    it "does not accept days outside 1 and 31" do
      expect { Automations::AnnualSchedule.new months: [1, 12], days: [-1, 2], times: [10, 22] }.to raise_error ArgumentError

      expect { Automations::AnnualSchedule.new months: [1, 12], days: [1, 32], times: [10, 22] }.to raise_error ArgumentError
    end

    it "accepts times between 0 and 23" do
      @schedule = Automations::AnnualSchedule.new months: [1, 12], days: [1, 2], times: [10, 22]

      expect(@schedule.times).to eq([10, 22])
    end

    it "does not accept times outside 0 and 23" do
      expect { Automations::AnnualSchedule.new months: [1, 12], days: [1, 2], times: [-1, 22] }.to raise_error ArgumentError

      expect { Automations::AnnualSchedule.new months: [1, 12], days: [1, 2], times: [10, 25] }.to raise_error ArgumentError
    end
  end

  context "#ready?" do
    it "must be supplied with a time" do
      @schedule = Automations::DailySchedule.new days: [5], times: [11]
      expect { @schedule.ready?(some: "data") }.to raise_error(Plumbing::PreConditionError)
    end

    it "is ready if the month, day and time match" do
      @schedule = Automations::AnnualSchedule.new months: [9], days: [28], times: [11]
      Timecop.travel Time.new(2024, 9, 28, 11, 0) do # Saturday, 28th September 2024, 11:00
        expect(@schedule.ready?(time: Time.now)).to be true
      end
    end

    it "is ready if the month and day match and the time is within the following hour" do
      @schedule = Automations::AnnualSchedule.new months: [9], days: [28], times: [11]
      Timecop.travel Time.new(2024, 9, 28, 11, 45) do # Saturday, 28th September 2024, 11:45
        expect(@schedule.ready?(time: Time.now)).to be true
      end
    end

    it "is not ready if the month does not match and the day and time match" do
      @schedule = Automations::AnnualSchedule.new months: [10, 11], days: [28], times: [11]
      Timecop.travel Time.new(2024, 9, 28, 11, 0) do # Saturday, 28th September 2024, 11:00
        expect(@schedule.ready?(time: Time.now)).to be false
      end
    end

    it "is not ready if the day does not match and the month and time match" do
      @schedule = Automations::AnnualSchedule.new months: [9], days: [29], times: [11]
      Timecop.travel Time.new(2024, 9, 28, 11, 0) do # Saturday, 28th September 2024, 11:00
        expect(@schedule.ready?(time: Time.now)).to be false
      end
    end

    it "is not ready if the month and day match and the time does not match" do
      @schedule = Automations::AnnualSchedule.new months: [9], days: [28], times: [12]
      Timecop.travel Time.new(2024, 9, 28, 11, 0) do # Saturday, 28thSeptember 2024, 11:00
        expect(@schedule.ready?(time: Time.now)).to be false
      end
    end
  end

  context "#to_h" do
    it "publishes its attributes" do
      @schedule = Automations::AnnualSchedule.new months: [2, 3], days: [5], times: [12]
      expect(@schedule.to_h).to eq({months: [2, 3], days: [5], times: [12]})
    end
  end
end
