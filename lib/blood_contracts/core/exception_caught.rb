module BloodContracts::Core
  # Refinement type which holds exception as a value
  class ExceptionCaught < ContractFailure
    # Constructs refinement type around exception
    #
    # @param value [Exception] value which is wrapped inside the type
    # @option context [Hash] shared context of types matching pipeline
    #
    def initialize(value = nil, context: Hash.new { |h, k| h[k] = {} }, **)
      @errors = []
      @context = context
      @value = value
      @context[:exception] = value
    end

    # Predicate, whether the data is valid or not
    # (for the ExceptionCaught it is always False)
    #
    # @return [Boolean]
    #
    def valid?
      false
    end

    # Reader for the exception caught
    #
    # @return [Exception]
    #
    def exception
      @context[:exception]
    end
  end
end
