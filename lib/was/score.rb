module WAS
  class Score
    attr_reader :input

    def self.maximum_score(value)
      @maximum_score = value
    end

    def self.max_score
      @maximum_score || 1
    end

    def self.with(klass, weight: 0)
      klasses.merge!(klass => weight)
    end

    def self.klasses
      @klasses ||= {}
    end

    def initialize(input)
      @input = input
    end

    def calculate
      calculation
    end

    def calculation
      self.class.klasses.sum do |klass, weight|
        score = Object.const_get(klass).new(input[klass_name_symbol(klass)]).calculate
        score * weight
      end * self.class.max_score
    end

    private

    def klass_name_symbol(klass)
      klass[/(\w+)Score$/, 1].downcase.to_sym
    end
  end
end
