# frozen_string_literal: true

RSpec.describe WAS::Tree do
  it "is a subclass of Hash" do
    expect(described_class.ancestors).to include(Hash)
  end

  let(:report_tree) do
    WAS::Tree.new.tap do |tree|
      tree[:score]     = 750
      tree[:max]       = 1000
      tree[:deduction] = -250
      tree[:weight]    = 1.0,
      tree[:with]      = {
        smaller: small_tree,
        bigger: big_tree
      }
    end
  end

  describe "#order" do
    context "ordering by :deduction" do
      let(:small_tree) do
        WAS::Tree.new.tap do |tree|
          tree[:score]     = 200
          tree[:max]       = 250
          tree[:deduction] = -50
          tree[:weight]    = 0.5
        end
      end

      let(:big_tree) do
        WAS::Tree.new.tap do |tree|
          tree[:score]     = 50
          tree[:max]       = 250
          tree[:deduction] = -200
          tree[:weight]    = 0.5
        end
      end

      it "returns a tree ordered by largest deductions" do
        expect(report_tree[:with].keys).to eq([:smaller, :bigger])
        expect(report_tree.order[:with].keys).to(
          eq([:bigger, :smaller])
        )
      end
    end

    context "ordering by :max" do
      let(:small_tree) do
        WAS::Tree.new.tap do |tree|
          tree[:score]     = 50
          tree[:max]       = 50
          tree[:deduction] = 0
          tree[:weight]    = 0.5
        end
      end

      let(:medium_tree) do
        WAS::Tree.new.tap do |tree|
          tree[:score]     = 150
          tree[:max]       = 150
          tree[:deduction] = 0
          tree[:weight]    = 0.5
        end
      end

      let(:big_tree) do
        WAS::Tree.new.tap do |tree|
          tree[:score]     = 100
          tree[:max]       = 100
          tree[:deduction] = 0
          tree[:weight]    = 0.5
          tree[:with]      = {
            smaller: small_tree,
            medium: medium_tree
          }
        end
      end

      it "returns a tree ordered by largest max values" do
        expect(report_tree[:with].keys).to eq([:smaller, :bigger])

        result = report_tree.order(:max)

        expect(result[:with].keys).to(
          eq([:bigger, :smaller])
        )

        expect(result[:with][:bigger][:with].keys).to(
          eq([:medium, :smaller])
        )
      end
    end
  end
end
