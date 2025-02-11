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
      scorers.merge!(name => { class_name: class_name, weight: weight })
    end

    def self.scorers
      @scorers ||= {}
    end

    def self.weights
      {}.tap do |hash|
        scorers.each do |name, scorer|
          hash[name] = { weight: scorer[:weight] }
          if Object.const_get(scorer[:class_name]).scorers.length > 0
            hash[name].merge!(
              with: Object.const_get(scorer[:class_name]).weights
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
      self.class.scorers.sum do |name, scorer|
        score = Object.const_get(scorer[:class_name]).new(input[name.to_sym]).calculate
        score * scorer[:weight]
      end * self.class.max_score
    end

    private

    def self.klass_name_symbol(klass)
      klass[/(\w+)Score$/, 1].downcase.to_sym
    end
  end
end
