Gem::Specification.new do |gem|
  gem.name          = "blood_contracts-ext"
  gem.version       = "0.1.3"
  gem.authors       = ["Sergey Dolganov (sclinede)"]
  gem.email         = ["sclinede@evilmartians.com"]

  gem.summary       = "Extra helpers for BloodContracts::Core"
  gem.description   = "Extra helpers for BloodContracts::Core"
  gem.homepage      = "https://github.com/sclinede/blood_contracts-ext"
  gem.license       = "MIT"

  gem.files            = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.test_files       = gem.files.grep(/^spec/)
  gem.extra_rdoc_files = Dir["CODE_OF_CONDUCT.md", "README.md", "LICENSE", "CHANGELOG.md"]

  gem.required_ruby_version = ">= 2.4"

  gem.add_runtime_dependency "blood_contracts-core", "~> 0.4"
  gem.add_runtime_dependency "tram-policy" , "~> 2.0"
  gem.add_runtime_dependency "i18n", "~> 1.0"

  gem.add_development_dependency "bundler", "~> 2.0"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "rubocop", "~> 0.49"
end
