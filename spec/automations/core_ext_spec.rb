require "rails_helper"

RSpec.describe "Core extensions" do
  describe "Integer" do
    describe "#between?" do
      it "is true if the value is between the minimum and maximum" do
        expect(5.between?(1, 10)).to be true
      end

      it "is false if the value is less than the minimum" do
        expect(0.between?(1, 10)).to be false
      end

      it "is false if the value is greater than the maximum" do
        expect(11.between?(1, 10)).to be false
      end
    end
  end

  describe "Time" do
    describe "#week_of_month" do
      it "is 1 if the time represents a date within the first week of the month" do
        expect(Time.new(2024, 8, 1).week_of_month).to eq 1
        expect(Time.new(2025, 1, 1).week_of_month).to eq 1
      end
      it "is 2 if the time represents a date within the second week of the month" do
        expect(Time.new(2024, 8, 7).week_of_month).to eq 2
        expect(Time.new(2025, 1, 7).week_of_month).to eq 2
      end
      it "is 3 if the time represents a date within the third week of the month" do
        expect(Time.new(2024, 8, 14).week_of_month).to eq 3
        expect(Time.new(2025, 1, 14).week_of_month).to eq 3
      end
      it "is 4 if the time represents a date within the fourth week of the month" do
        expect(Time.new(2024, 8, 21).week_of_month).to eq 4
        expect(Time.new(2025, 1, 21).week_of_month).to eq 4
      end
      it "is 5 if the time represents a date within the fifth week of the month" do
        expect(Time.new(2024, 8, 28).week_of_month).to eq 5
        expect(Time.new(2025, 1, 28).week_of_month).to eq 5
      end
    end
  end
end
