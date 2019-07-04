module BloodContracts::Core
  # ContractFailure which holds errors in form of Tram::Policy::Errors
  class PolicyFailure < ContractFailure
    # Extends the type with ability to generate custom errors, to wrap and
    # error message into Tram::Policy::Errors
    extend DefineableError.new(:contracts)

    # Builds an PolicyFailure, turns the errors into Tram::Policy::Errors
    # if they are not, yet
    #
    # @param errors_per_type [Hash<Refined, Array<String,Symbol>>] map of
    #   errors per type, each type could have a list of errors
    # @option context [Hash] shared context of  matching pipeline
    #
    def initialize(errors_per_type = nil, context: {}, **)
      sub_scope = context.delete(:sub_scope)
      errors_per_type.to_h.transform_values! do |errors|
        errors.map do |error|
          next(error) if error.is_a?(Tram::Policy::Errors)
          self.class.define_error(error, tags: context, sub_scope: sub_scope)
        end
      end
      super
    end

    # Merged list of Tram::Policy::Errors after the matching run
    #
    # @return [Array<Tram::Policy::Errors>]
    #
    def policy_errors
      @policy_errors ||= @value.values.flatten
    end

    # Merged list of Tram::Policy::Errors messages (or their translations)
    #
    # @return [Array<String>]
    #
    def messages
      @messages ||= policy_errors.map(&:messages).flatten
    end
  end
end
