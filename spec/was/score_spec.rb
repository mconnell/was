# frozen_string_literal: true

RSpec.describe WAS::Score do
  subject { described_class.new(nil) }

  # class ReportScore < WAS::Score
  #   maximum_score 1000

  #   with ExamScore,       weight: 0.75
  #   with PracticalScore,  weight: 0.25
  # end

  # class ExamScore < WAS::Score
  #   def calculation
  #     return 1    if value == "A"
  #     return 0.75 if value == "B"
  #     return 0.5  if value == "C"
  #     0
  #   end
  # end

  class PracticalScore < WAS::Score
    def calculation
      input / 10.0
    end
  end

  describe "PracticalScore#calculate" do
    it "returns 0 if input value is 0" do
      expect(PracticalScore.new(0).calculate).to eq(0)
    end

    it "returns 0.2 if input value is 2" do
      expect(PracticalScore.new(2).calculate).to eq(0.2)
    end

    it "returns 1 if input value is 10" do
      expect(PracticalScore.new(10).calculate).to eq(1)
    end
  end
end
