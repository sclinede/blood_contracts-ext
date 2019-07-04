module BloodContracts::Core
  # Concern to wrap matching process with exception handling
  #
  # @example Defines a type with automatic exception handling in form of types
  #   class JsonType < ::BC::Refined
  #     prepend ExceptionHandling
  #
  #     def match
  #       @context[:parsed_json] = JSON.parse(value)
  #       self
  #     end
  #   end
  #
  module ExceptionHandling
    # Runs the matching process and returns an ExceptionCaught if
    # StandardError happened inside match call
    #
    # @return [Refined]
    #
    def match
      super
    rescue StandardError => ex
      exception(ex)
    end

    # Wraps the exception in refinement type
    #
    # @param exc [Exception] raised exception
    # @option context [Hash] shared context of matching pipeline
    # @return [ExceptionCaught]
    #
    def exception(exc, context: @context)
      ExceptionCaught.new(exc, context: context)
    end
  end
end
