module WAS
  class Tree < Hash
    def order(order_key = :deduction)
      self.dup.tap do |tree|
        return tree if tree[:with].nil?

        sort_with_by!(order_key, tree)
      end
    end

    private

    def sort_with_by!(order_key, tree)
      return tree if tree[:with].nil?

      tree[:with].each do |scorer, branch|
        sort_with_by!(order_key, branch)
      end

      array = tree[:with].sort_by do |_, subtree|
        subtree[order_key]
      end

      tree[:with] = if order_key == :deduction
        array.to_h
      else
        array.reverse.to_h
      end
    end
  end
end
