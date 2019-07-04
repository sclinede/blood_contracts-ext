module BloodContracts::Core
  module Ext
    # Refinement types representation of Sum types composition, extended version
    class Sum < ::BC::Sum
      # Sets the default failure_klass to PolicyFailure, to use
      # Tram::Policy::Errors for errors
      self.failure_klass = SumPolicyFailure

      # @private
      def self.inherited(new_klass)
        new_klass.failure_klass ||= failure_klass
        super
      end

      # Generate an PolicyFailure from the error, also stores the
      # additional scope for Tram::Policy::Errors in the context.
      # Also saves the Sum errors in the context
      #
      # @param (see BC::Refined#failure)
      # @return [PolicyFailure]
      #
      def failure(*, **)
        @context[:sum_errors] = @or_matches
        @context[:sub_scope] = self.class.name
        super
      end
    end
  end
end
