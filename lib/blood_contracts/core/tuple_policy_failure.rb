module BloodContracts::Core
  # Represents failure in Tuple data matching
  class TuplePolicyFailure < PolicyFailure
    # Hash of attributes (name & type pairs)
    #
    # @return [Hash<String, Refined>]
    #
    def attributes
      @context[:attributes]
    end

    # Subset of attributes which are invalid
    #
    # @return [Hash<String, PolicyFailure>]
    #
    def attribute_errors
      attributes.select { |_name, type| type.invalid? }
    end

    # Subset of attributes which are invalid
    #
    # @return [Hash<String, PolicyFailure>]
    #
    def attribute_messages
      attribute_errors.transform_values!(&:messages)
    end

    # Unpacked matching errors in form of a hash per attribute
    #
    # @return [Hash<String, PolicyFailure>]
    #
    def unpack_h
      @unpack_h ||= attribute_errors.transform_values(&:unpack)
    end
    alias to_hash unpack_h
    alias to_h unpack_h
    alias unpack_attributes unpack_h
  end
end
