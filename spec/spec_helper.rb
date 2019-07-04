require "bundler/setup"
require "blood_contracts/ext"

require_relative "support/fixtures_helper.rb"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around do |example|
    I18n.available_locales = %w[en]
    I18n.backend.store_translations :en, yaml_fixture_file("en.yml")["en"]
    module Test; end
    example.run
    Object.send(:remove_const, :Test)
  end
end
