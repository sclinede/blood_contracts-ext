module BloodContracts::Core
  # Meta class to define local errors in form of Tram::Policy::Errors
  module DefineableError
    # Concern with the helper to define custom Tram::Policy::Errors
    module Concern
      # @private
      def inherited(other)
        super
        other.instance_variable_set(:@policy_scope, @policy_scope)
      end

      # Method that turns message into Tram::Policy::Errors object
      #
      # @param message [String, Symbol] (or translations key) for your
      #   custom error
      # @option tags [Hash] additional context for translations
      # @option sub_scope [Symbol] is a customizable path to your
      #   translation
      # @return [Tram::Policy::Error]
      #
      def define_error(message, tags: {}, sub_scope: nil)
        errors = Tram::Policy::Errors.new(scope: @policy_scope)
        sub_scope = underscore(sub_scope || name)
        message = [sub_scope, message].join(".").to_sym if message.is_a?(Symbol)
        errors.add message, **tags
        errors
      end

      # @private
      private def underscore(string)
        return string.underscore if string.respond_to?(:underscore)

        string.gsub(/([A-Z]+)([A-Z])/, '\1_\2')
              .gsub(/([a-z])([A-Z])/, '\1_\2')
              .gsub("__", "/")
              .gsub("::", "/")
              .gsub(/\s+/, "") # spaces are bad form
              .gsub(/[?%*:|"<>.]+/, "") # reserved characters
              .downcase
      end
    end

    class << self
      # Method that creates meta class for defining custom Tram::Policy::Errors
      #
      # @param policy_scope [Symbol] is a root for your I18n translations
      # @return [Module]
      #
      def new(policy_scope)
        m = Module.new do
          def self.extended(other)
            other.instance_variable_set(
              :@policy_scope, instance_variable_get(:@policy_scope)
            )
          end
        end
        m.include(Concern)
        m.instance_variable_set(:@policy_scope, policy_scope)
        m
      end
    end
  end
end
