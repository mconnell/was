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

    def self.context(name, score: nil, &block)
      @contexts ||= []
      @contexts.push({ name: name, score: score, code: block })
    end

    def initialize(input)
      @input = input
    end

    def calculate
      calculation
    end

    def calculation
      if contexts?
        context_score_calculation
      else
        nested_score_calcuation
      end
    end

    private

    def contexts?
      !!self.class.instance_variable_get("@contexts")
    end

    def context_score_calculation
      self.class.instance_variable_get("@contexts").each do |context|
        output = context[:code].call(input)
        next unless output
        return context[:score] || output
      end
    end

    def nested_score_calcuation
      self.class.scorers.sum do |name, scorer|
        score = Object.const_get(scorer[:class_name]).new(input[name.to_sym]).calculate
        score * scorer[:weight]
      end * self.class.max_score
    end
  end
end
