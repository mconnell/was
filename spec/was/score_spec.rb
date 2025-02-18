# frozen_string_literal: true

RSpec.describe WAS::Score do
  subject { described_class.new(nil) }

  class NestedScore < WAS::Score
    with :composed, class_name: "ComposedScore", weight: 1.0
  end

  class ComposedScore < WAS::Score
    with :exam,     class_name: "ExamScore",      weight: 0.75
    with :practical, class_name: "PracticalScore", weight: 0.25
  end

  class ReportScore < WAS::Score
    maximum_score 1000

    with :exam,     class_name: "ExamScore",      weight: 0.75
    with :practical, class_name: "PracticalScore", weight: 0.25
  end

  class ExamScore < WAS::Score
    def calculation
      return 1    if input == "A"
      return 0.75 if input == "B"
      return 0.5  if input == "C"
      0
    end
  end

  class PracticalScore < WAS::Score
    def calculation
      input / 10.0
    end
  end

  class ContextScore < WAS::Score
    context :fixed_score, score: 0.5 do |input|
      input == "FIXED"
    end

    context :variable_score do |input|
      input / 10.0
    end
  end

  describe "ContextScore" do
    it "returns a fixed score 0.5 if input is 'FIXED'" do
      expect(ContextScore.new("FIXED").calculate).to eq(0.5)
    end

    it "returns a variable score depending on the input" do
      expect(ContextScore.new(9).calculate).to eq(0.9)
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

  describe "ExamScore#calculate" do
    it "returns 1 if input value is 'A'" do
      expect(ExamScore.new('A').calculate).to eq(1)
    end

    it "returns 0.75 if input value is 'B'" do
      expect(ExamScore.new('B').calculate).to eq(0.75)
    end

    it "returns 0.5 if input value is 'C'" do
      expect(ExamScore.new('C').calculate).to eq(0.5)
    end

    it "returns 0 if input value is 'F'" do
      expect(ExamScore.new('D').calculate).to eq(0)
    end
  end

  describe "ReportScore#calculate" do
    context "scored 0/10 in practical, failed exam with 'F'" do
      it "returns a calculated score of 0" do
        expect(
          ReportScore.new({
            practical: 0,
            exam: "F"
          }).calculate
        ).to eq(0)
      end
    end

    context "passed practical with 10, failed exam with an 'F'" do
      it "returns a calculated score of 250" do
        expect(
          ReportScore.new({
            practical: 10,
            exam: "F"
          }).calculate
        ).to eq(250)
      end
    end

    context "Scored 8/10 in practical, passed exam with an 'C'" do
      it "returns a calculated score of 575" do
        expect(
          ReportScore.new({
            practical: 8,
            exam: "C"
          }).calculate
        ).to eq(575)
      end
    end

    context "Failed practical, passed exam with an 'A'" do
      it "returns a calculated score of 750" do
        expect(
          ReportScore.new({
            practical: 0,
            exam: "A"
          }).calculate
        ).to eq(750)
      end
    end

    context "Scored 10/10 in practical, passed exam with an 'A'" do
      it "returns a calculated score of 1000" do
        expect(
          ReportScore.new({
            practical: 10,
            exam: "A"
          }).calculate
        ).to eq(1000)
      end
    end
  end

  describe "ComposedScore#calculate" do
    context "no 'maximum_score' defined. 5/10 in practical, passed exam with 'A'" do
      it "returns a calculated score of 0.875" do
        expect(
          ComposedScore.new({
            practical: 5,
            exam: "A"
          }).calculate
        ).to eq(0.875)
      end
    end
  end

  describe "NestedScore#calculate" do
    context "nested score results. no 'maximum_score' defined. 5/10 in practical, passed exam with 'A'" do
      it "returns a calculated score of 0.875" do
        expect(
          NestedScore.new(
            composed: {
              practical: 5,
              exam: "A"
            }
          ).calculate
        ).to eq(0.875)
      end
    end
  end

  describe "WAS::Score#weights" do
    it "emits a hash of scoring rules with their weights" do
      expect(
        NestedScore.weights
      ).to eq({
        composed: {
          weight: 1.0,
          with: {
            practical: { weight: 0.25 },
            exam: { weight: 0.75 }
          }
        }
      })
    end
  end
end
