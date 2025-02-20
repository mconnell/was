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
      calc = calculation(:tree)

      result = { max: self.class.max_score }
      tree = if calc.is_a?(Hash)
        calc.merge(result)
      else
        { score: calc }.merge(result)
      end

      if option == :tree
        transform_scores_relative_to_max_score(tree)
      else
        tree[:score]
      end
    end

    def calculation(option = nil)
      if contexts?
        context_score_calculation
      else
        nested_score_calcuation(option)
      end
    end

    private

    def transform_scores_relative_to_max_score(tree, max_score = nil)
      max_score = max_score || self.class.max_score
      return tree if self.class.max_score == 1

      tree.each do |key, value|
        next if key != :with

        value.each do |scorer, branch|
          adjust_branch_score_and_max(branch, max_score)
        end

        value.transform_values! do |nested_tree|
          transform_scores_relative_to_max_score(nested_tree, nested_tree[:max])
        end
      end
    end

    def adjust_branch_score_and_max(branch, max_score)
      branch[:max]   = branch[:max] * max_score * branch[:weight]
      branch[:score] = branch[:score] * branch[:max]
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
        { score: sum, with: with_attribute }
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
