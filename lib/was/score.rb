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

    def calculate(option = nil)
      return calculation if option != :tree

      calc = calculation(:tree)
      tree = if calc.is_a?(Hash)
        calc.merge(additional_score_attributes(calc[:score]))
      else
        {}.tap do |t|
          t.merge!(score: calc)
          t.merge!(additional_score_attributes(calc))
        end
      end

      transform_scores_relative_to_max_score(tree)
    end

    def calculation(option = nil)
      if contexts?
        context_score_calculation
      else
        nested_score_calcuation(option)
      end
    end

    private

    def additional_score_attributes(score_value)
      {
        max: self.class.max_score,
        deduction: (score_value - self.class.max_score).round(8)
      }
    end

    def transform_scores_relative_to_max_score(tree, max_score = nil)
      max_score = max_score || self.class.max_score
      return tree if self.class.max_score == 1

      tree.each do |key, value|
        next if key != :with

        value.each do |scorer, branch|
          adjust_values_relative_to_max_score(branch, max_score)
        end

        value.transform_values! do |nested_tree|
          transform_scores_relative_to_max_score(nested_tree, nested_tree[:max])
        end
      end
    end

    def adjust_values_relative_to_max_score(branch, max_score)
      branch[:max] = branch[:max] * max_score * branch[:weight]
      branch[:score] = branch[:score] * branch[:max]
      branch[:deduction] = branch[:score] - branch[:max]
    end

    def contexts?
      !!self.class.instance_variable_get("@contexts")
    end

    def context_score_calculation
      self.class.instance_variable_get("@contexts").each do |context|
        output = context[:code].call(input)
        next if !output
        return context[:score] || output
      end
    end

    def nested_score_calcuation(option)
      if option == :tree
        WAS::Tree.new.tap do |t|
          t[:score] = sum
          t[:with]  = with_attribute
        end
      else
        sum
      end
    end

    def sum
      @sum ||= self.class.scorers.sum do |name, scorer|
        score = Object.const_get(scorer[:class_name]).new(input[name.to_sym]).calculate
        score * scorer[:weight]
      end * self.class.max_score
    end

    def with_attribute
      {}.tap do |with|
        self.class.scorers.each do |name, scorer|
          with[name] = Object.const_get(scorer[:class_name]).new(input[name.to_sym]).calculate(:tree)
          with[name][:weight] = scorer[:weight]
        end
      end
    end
  end
end
