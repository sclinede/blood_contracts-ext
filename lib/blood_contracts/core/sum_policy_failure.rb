module BloodContracts::Core
  # Represents failure in Sum data matching
  class SumPolicyFailure < PolicyFailure
    # Accessor to contexts of Ext::Sum failed matches
    #
    # @return [Array<Hash>]
    def contexts
      @context[:sum_failure_contexts]
    end

    # Custom accessor for policy errors in case of Ext::Sum types composition
    def policy_errors
      @policy_errors ||= @context[:sum_errors].map(&:policy_errors).flatten
    end
  end
end
