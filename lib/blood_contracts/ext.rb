require "blood_contracts/core"
require "tram-policy"

# Top-level scope for BloodContracts toolset
module BloodContracts
  # Scope for refinement types & helpers for them
  module Core
    require_relative "core/defineable_error.rb"

    require_relative "core/policy_failure.rb"
    require_relative "core/tuple_policy_failure.rb"
    require_relative "core/sum_policy_failure.rb"
    require_relative "core/exception_caught.rb"
    require_relative "core/exception_handling.rb"
    require_relative "core/extractable.rb"

    # Scope for extended refinement types
    module Ext
      require_relative "ext/refined.rb"
      require_relative "ext/sum.rb"
      require_relative "ext/pipe.rb"
      require_relative "ext/tuple.rb"
    end

    require_relative "core/expected_error.rb"
    require_relative "core/map_value.rb"
  end
end
