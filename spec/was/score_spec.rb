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
    context :grade_a, score: 1 do |input|
      input == "A"
    end

    context :grade_b, score: 0.75 do |input|
      input == "B"
    end

    context :grade_c, score: 0.5 do |input|
      input == "C"
    end

    context :flunk do
      0
    end
  end

  class PracticalScore < WAS::Score
    context :score do |input|
      input / 10.0
    end
  end

  class ComplexNestedScore < WAS::Score
    maximum_score 1000

    with :theory, class_name: "TheoryScore", weight: 0.5
    with :composed, class_name: "ComposedScore", weight: 0.5
  end

  class TheoryScore < WAS::Score
    context :score do |input|
      input / 10.0
    end
  end


  describe "ComplexNestedScore#calculate" do
    context "no option supplied" do
      it "returns just the score" do
        expect(
          ComplexNestedScore.new({
            theory: 8,
            composed: {
              practical: 5,
              exam: "C"
            }
          }).calculate).to eq(650)
      end
    end

    context ":tree option supplied" do
      let(:tree) do
        ComplexNestedScore.new({
          theory: 8,
          composed: {
            practical: 5,
            exam: "C"
          }
        }).calculate(:tree)
      end

      it "has a total score of 650" do
        expect(tree[:score]).to eq(650)
      end

      it "has a maximum score of 1000" do
        expect(tree[:max]).to eq(1000)
      end

      it "includes a breakdown of the theory score" do
        expect(tree[:with][:theory]).to(
          eq({ score: 400, max: 500, weight: 0.5 })
        )
      end

      describe "composed score" do
        it "includes a composed overall score" do
          expect(tree[:with][:composed][:score]).to eq(250)
        end

        it "includes a composed max value" do
          expect(tree[:with][:composed][:max]).to eq(500)
        end

        it "includes a composed weight" do
          expect(tree[:with][:composed][:weight]).to eq(0.5)
        end

        it "includes a breakdown of the 'practical' score" do
          expect(tree[:with][:composed][:with][:practical]).to(
            eq({ score: 62.5, max: 125, weight: 0.25 })
          )
        end
        it "includes a breakdown of the 'exam' score" do
          expect(tree[:with][:composed][:with][:exam]).to(
            eq({ score: 187.5, max: 375, weight: 0.75 })
          )
        end

        it "composed tree max scores roll up to the composed max score" do
          expect(tree[:with][:composed][:max]).to eq(
            tree[:with][:composed][:with][:practical][:max] + tree[:with][:composed][:with][:exam][:max]
          )
        end
      end
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

    context ":tree option supplied" do
      it "returns a calculated score of 575 with breakdown" do
        expect(
          ReportScore.new({
            practical: 8,
            exam: "C"
          }).calculate(:tree)
        ).to eq({
          score: 575.0,
          max: 1000,
          with: {
            practical: {
              score: 200,
              max: 250,
              weight: 0.25
            },
            exam: {
              score: 375,
              max: 750,
              weight: 0.75
            }
          }
        })
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

    context ":tree option supplied" do
      it "returns a calculated score of 1 with breakdown" do
        expect(
          ComposedScore.new({
            practical: 8,
            exam: "C"
          }).calculate(:tree)
        ).to eq({
          score: 0.575,
          max: 1,
          with: {
            practical: {
              score: 0.8,
              max: 1,
              weight: 0.25
            },
            exam: {
              score: 0.5,
              max: 1,
              weight: 0.75
            }
          }
        })
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
