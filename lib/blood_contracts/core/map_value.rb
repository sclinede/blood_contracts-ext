module BloodContracts::Core
  # Mapper in form of refinement type, transforms the value using mapper_klass
  class MapValue < Refined
    class << self
      # Any callable object which you prefer to turn value into other form
      #
      # @param [Class, #call]
      # @return [Class]
      #
      attr_accessor :mapper_klass

      # Generates meta-class with predefined mapper_klass
      #
      # @param mapper_klass [Class, callable] callable object that will
      #   transform the value
      # @return [MapValue]
      #
      def with(mapper_klass)
        type = Class.new(self)
        type.mapper_klass = mapper_klass
        type
      end
    end

    # Always successful matching process which transforms the value and
    # store it in the context
    #
    # @return [Refined]
    #
    def match
      context[:mapped_value] = self.class.mapper_klass.call(**value)
      self
    end

    # Mapped representation of the value
    #
    # @return [Object]
    #
    def mapped
      match.context[:mapped_value]
    end
  end
end
