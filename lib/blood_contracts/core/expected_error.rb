module BloodContracts::Core
  # Custom refinement type that converts the extracted data into
  # Tram::Policy::Errors, could by used when the case is an error but
  # you know how to deal with it inside application
  class ExpectedError < Ext::Refined
    # Generates an Tram::Policy::Errors message using the matching context
    #
    # @return [Tram::Policy::Errors]
    def mapped
      keys = self.class.extractors.keys
      tags = Hash[keys.zip(@context.values_at(*keys))]
      tags = @context if tags.empty?
      self.class.define_error(:message, tags: tags)
    end
  end
end
