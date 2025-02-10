module WAS
  class Score
    attr_reader :input

    def initialize(input)
      @input = input
    end

    def calculate
      calculation
    end
  end
end
