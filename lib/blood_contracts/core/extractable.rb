module BloodContracts::Core
  # Concern that turns your refinement type into a coercer with validation
  # delegated to Tram::Policy
  module Extractable
    # @private
    def self.included(other_class)
      other_class.extend(ClassMethods)
    end

    # DSL definition
    module ClassMethods
      # Configuration about how to extract data from the value, just
      # list of context keys and methods
      attr_reader :extractors

      # Tram::Policy ancestor that will be used for validation
      #
      # @param [Class]
      #
      attr_accessor :policy

      # @private
      def inherited(child)
        super
        child.instance_variable_set(:@extractors, {})
      end

      # DSL to define which method to use to extract data from the value
      #
      # @param extractor_name [Symbol] key to store the extracted data in the
      #   context
      # @option method_name [Symbol] custom method name to use for extraction
      # @return [Nothing]
      #
      def extract(extractor_name, method_name: extractor_name)
        extractors[extractor_name] = [method_name]
      end
    end

    # Turns matching process into 2 steps:
    # - extraction of data from the value
    # - validation using the policy_klass
    #
    # @return [Refined]
    def match
      extract!
      policy_failure_match! || self
    end

    # Turns value into the hash of extracted data
    #
    # @return [Hash]
    def mapped
      @context.slice(*self.class.extractors.keys)
    end

    # Extracts data from the value
    #
    # @return [Nothing]
    #
    protected def extract!
      self.class.extractors.each do |field, settings|
        next if !context[field].nil? && !context[field].empty?

        method_name, = *settings
        context[field] = send(method_name.to_s)
      end
    end

    # Validates extracted data using policy_klass
    #
    # @return [Refined, Nil]
    #
    protected def policy_failure_match!
      return unless self.class.policy

      policy_input = context.transform_keys(&:to_sym)
      policy_instance = self.class.policy[**policy_input]
      return if policy_instance.valid?

      failure(policy_instance.errors)
    end
  end
end
