module WAS
  class Score
    attr_reader :input

    def self.maximum_score(value)
      @maximum_score = value
    end

    def self.max_score
      @maximum_score || 1
    end

    def self.with(name, class_name: klass, weight: 0)
      scorers.merge!(class_name => weight)
    end

    def self.scorers
      @scorers ||= {}
    end

    def self.weights
      {}.tap do |hash|
        scorers.each do |klass, weight|
          hash[klass_name_symbol(klass)] = { weight: weight }
          if Object.const_get(klass).scorers.length > 0
            hash[klass_name_symbol(klass)].merge!(
              with: Object.const_get(klass).weights
            )
          end
        end
      end
    end

    def initialize(input)
      @input = input
    end

    def calculate
      calculation
    end

    def calculation
      self.class.scorers.sum do |klass, weight|
        score = Object.const_get(klass).new(input[self.class.klass_name_symbol(klass)]).calculate
        score * weight
      end * self.class.max_score
    end

    private

    def self.klass_name_symbol(klass)
      klass[/(\w+)Score$/, 1].downcase.to_sym
    end
  end
end
