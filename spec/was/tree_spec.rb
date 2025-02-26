# frozen_string_literal: true

RSpec.describe WAS::Tree do
  it "is a subclass of Hash" do
    expect(described_class.ancestors).to include(Hash)
  end
end
