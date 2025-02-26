module WAS
  class Tree < Hash
    def order(order_key = :deduction)
      self.dup.tap do |tree|
        return tree if tree[:with].nil?

        if order_key == :deduction
          tree[:with] = sorted_with_by(order_key, tree).to_h
        else
          tree[:with] = sorted_with_by(order_key, tree).reverse.to_h
        end
      end
    end

    private

    def sorted_with_by(order_key, tree)
      return tree if tree[:with].nil?

      tree[:with].sort_by do |_, subtree|
        subtree[order_key]
      end
    end
  end
end
