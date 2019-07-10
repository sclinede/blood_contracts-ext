module BloodContracts::Core
  module Ext
    # Refinement type exteneded with Extractable, ExceptionHandling and
    # errors representation in form of Tram::Policy::Errors
    class Refined < ::BC::Refined
      # Adds ability to generate custom errors in form of Tram::Policy::Errors
      extend DefineableError.new(:contracts)

      # Adds extractors DSL
      include Extractable

      # Adds exception handling in form of refinment type
      prepend ExceptionHandling

      # Sets the default failure_klass to PolicyFailure, to use
      # Tram::Policy::Errors for errors
      self.failure_klass = PolicyFailure

      class << self
        # Compose types in a Sum check
        # Sum passes data from type to type in parallel, only one type
        # have to match
        #
        # @return [BC::Sum]
        #
        def or_a(other_type)
          BC::Ext::Sum.new(self, other_type)
        end

        # Alias for Sum compose
        # See #or_a
        alias or_an or_a

        # Alias for Sum compose
        # See #or_a
        alias | or_a

        # Compose types in a Pipe check
        # Pipe passes data from type to type sequentially
        #
        # @return [BC::Pipe]
        #
        def and_then(other_type)
          BC::Ext::Pipe.new(self, other_type)
        end

        # Alias for Pipe compose
        # See #and_then
        alias > and_then

        # @private
        def inherited(new_klass)
          new_klass.failure_klass ||= failure_klass
          new_klass.prepend ExceptionHandling
          super
        end
      end

      # Generate an PolicyFailure from the error, also stores the
      # additional scope for Tram::Policy::Errors in the context
      #
      # @param (see BC::Refined#failure)
      # @return [PolicyFailure]
      #
      def failure(*, **)
        @context[:sub_scope] = self.class.name
        super
      end
    end
  end
end
