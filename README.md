[![Build Status](https://travis-ci.org/sclinede/blood_contracts-ext.svg?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/sclinede/blood_contracts-ext/badges/gpa.svg)][codeclimate]

[gem]: https://rubygems.org/gems/blood_contracts-ext
[travis]: https://travis-ci.org/sclinede/blood_contracts-ext
[codeclimate]: https://codeclimate.com/github/sclinede/blood_contracts-ext

# BloodContracts::Ext

Refinement types are implemented in BloodContracts::Core, but in production we found several patterns to use with types.
Let me share them with you.

Welcome, **extended refinement types**.

All those extensions are listed below, stay tuned.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blood_contracts-ext'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blood_contracts-ext

## Usage

This gems consists mostly of Concerns and Refined classes that extends the powers of refinement types.

### BC::ExceptionHandling

First of all sometimes it is great to replace the usual exception handling with refinement types, because
inside type you have much more context then just the exception and its backtrace.

For that scenario you only need to prepend your BC::Refined class with BC::ExceptionHandling and when
the StandardError happen inside your matching pipeline it will turn into BC::ExceptionCaught type
(which is of course just another ancestor of BC::ContractFailure).

```ruby
class JsonType < BC::Refined
  prepend BC::ExceptionHandling

  def match
    @context[:json_type_input] = value
    @context[:parsed_json] = JSON.parse(@context[:json_type_input])
    self
  end
end

match = JsonType.match(Class.new) # => #<BC::ExceptionCaught ...>
match.exception # => TypeError
match.context # => { :json_type_input => #<Class>, :exception => TypeError }
```

Now you have access to both the exception (the `#exception` reader) and matching context (the `#context` reader).

### BC::DefinableError

Imagine you have an error message you want to return for your validation, but you have to worry about the translations.
With BC::DefineableError you don't have to. You just extend your class with `BC::DefinableError.new(:translations_root)` and
you have simple DSL to define translatable and composable errors.

```ruby
class EmailType < ::BC::Refined
  extend BC::DefineableError.new(:type_validations)
  REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  INVALID_EMAIL = define_error(:invalid_email)

  def match
    context[:email_input] = value.to_s
    return failure(INVALID_EMAIL) if context[:email_input] !~ REGEX
    context[:email] = context[:email_input]

    self
  end
end

match = Email.match("not-an-email") # => #<BC::ContractFailure ...>

# en.yml should include translation for en.type_validations.email_type.invalid_email
# e.g. "Given value is not a valid email address"
match.errors.reduce(:merge).messages # => ["Given value is not a valid email address"]
```

Of course you may prefer a shortcut here, when you use ::BC::Ext::Refined as a base class your failures are
wrapped into BC::PolicyFailure with even better Tram::Policy integration.

```ruby
class EmailType < ::BC::Ext::Refined
  extend BC::DefineableError.new(:type_validations)
  REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  INVALID_EMAIL = define_error(:invalid_email)

  def match
    context[:email_input] = value.to_s
    return failure(INVALID_EMAIL) if context[:email_input] !~ REGEX
    context[:email] = context[:email_input]

    self
  end
end

match = Email.match("not-an-email") # => #<BC::PolicyFailure ...>

# en.yml should include translation for en.type_validations.email_type.invalid_email
# e.g. "Given value is not a valid email address"
match.messages # => ["Given value is not a valid email address"]
```

As simple as that! Do you still remember our "patter matching" usage?
It's working anyways:

```ruby
case match = Email.match("not-an-email")
when Email
  # Validation succeeded
  # Use #unpack or #context to extract the data
  match # => #<Email ...>
when BC::PolicyFailure
  # You have access here to #message and #policy_errors methods
  match # => #<BC::PolicyFailure ...>
when BC::ContractFailure
  # No fancy Tram::Policy integration but anyway #unpack or #messages at your serivce
  match # => #<BC::ContractFailure>
else raise # Remember to be exhaustive
end
```

### BC::MapValue

Another usual scenario is to transform the value of your type but when logic is too complex
you prefer to use another class for that. For that case you may try BC::MapValue type which
will be regular part of your pipeline.

Let's imagine you want to change transform your ActiveModel object to some json through the class.
Not a big deal, look at the example:

```ruby
module UPS
  class JsonRequests::Rates
    def self.call(origin_country:, destination_country:, weight:)
      JSON.pretty_generate(
        "RateRequest": {
          "Shipment": {
            "ShipFrom": origin_country,
            "ShipTo":   destination_country,
            "Service": { "Code": "65" },
            "Package": {
              "PackagingType": { "Code": "00" },
              "PackageWeight": {
                "UnitOfMeasurement": { "Code": "KGS" },
                "Weight": weight.to_s,
              }
            }
          }
        }
      )
    end
  end

  class ParcelType < BC::Refined
    prepend BC::ExceptionHandling

    def match
      parcel = value
      context.merge!(
        origin_country: parcel.origin_address.country,
        destination_country: parcel.destination_address.country,
        weight: parcel.weight
      )
    end

    def mapped
      @context.slice(:origin_country, :destination_country, :weight)
    end
  end

  RatesRequestType = ParcelType.and_then(BC::MapValue.with(JsonRequests::Rates))
end

match = UPS::RatesRequestType.match(Parcel.find(123)) # => #<BC::MapValue ...>
match.unpack # =>
# => {
#      "RateRequest": {
#        "Shipment": {
#          "ShipFrom": "LV",
#          "ShipTo":   "US",
#          "Service": { "Code": "65" },
#          "Package": {
#            "PackagingType": { "Code": "00" },
#            "PackageWeight": {
#              "UnitOfMeasurement": { "Code": "KGS" },
#              "Weight": "1.15"
#            }
#          }
#        }
#      }
#    }

UPS::RatesRequestType.match("not-a-parcel")   # => #<BC::ExceptionCaught ...>
```

### BC::Extractable

You may notice that in huge number of cases your type is a coercer from an arbitrary object.
So you may look at the Refinement type as "extractor".
That only means you have to use several methods to parse the context from the value.

That best example is attempt to use single type for different types of input

```ruby
class AddressType < BC::Refined
  extend BC::Extractable
  prepend BC::ExceptionHandling

  extract :city
  extract :country_code, method_name: :country
  extract :street

  def city
    return value.city if value.respond_to?(:city)
    value.to_h
         .transform_keys(&:to_s)
         .values_at("city", "City")
         .compact
         .first
  end

  def country
    return value.country if value.respond_to?(:country)
    value.to_h
         .transform_keys(&:to_s)
         .values_at("country", "country_code", "CountryCode")
         .compact
         .first
  end

  def street
    return value.street if value.respond_to?(:street)
    value.to_h
         .transform_keys(&:to_s)
         .values_at("street", "street_line", "StreetLine")
         .compact
         .first
  end
end

Address = Struct.new(:country, :city, :street)
```

That's just a definition, but let's take a look how it will behave in runtime:

```ruby
address_model = Address.new("RU", "Moscow", "Novoslobodskaya street")
AddressType.match(address_model) # => #<AddressType ...>

json_address = '{"CountryCode": "RU", "City": "Moscow", "StreetLine": "ul. Novoslobodskaya"}'
AddressType.match(JSON.parse(json_address)) # => #<AddressType ...>

AddressType.match("anything_else") # => #<BC::ExceptionCaught ...>
```

### BC::PolicyFailure

There is a great abstraction for validation called Policy object. I like the Tram::Policy implementation, so
now you're able to delegate validation logic to an external Policy object.

But, sometimes you may prefer to use only Tram::Policy::Errors abstraction for the matching errors.
For that case, you just need to use `self.failure_klass = BC::PolicyFailure` in your type.

```ruby
class Phone < ::BC::Refined
  self.failure_klass = BC::PolicyFailure
  REGEX = /\A(\+7|8)(9|8)\d{9}\z/i

  def match
    context[:phone_input] = value.to_s
    clean_phone = context[:phone_input].gsub(/[\s\(\)-]/, "")

    # translation key is: en.tram-policy.phone.invalid_phone
    return failure(:invalid_phone) if clean_phone !~ REGEX
    context[:clean_phone] = clean_phone

    self
  end
end
```

Not a big difference? But, now all your failure calls generate Tram::Policy::Error, which easily translates
using I18n.

### BC::Ext::Refined

You just saw several fancy tools around the BC::Refined. So, why don't we have everything inside that class?
Because we try to keep things simple and transparent. But.

If you prefer to have all that tooling in your types - "easy-peasy", use brand new BC::Ext::Refined.

BC::Ext::Refined - is just extended version of BC::Refined (extended by concerns mentioned above).

### BC::ExpectedError

Finally, when you validate responses from API, sometimes "error" is just one of expected scenarios.
That is why you may prefer special base class for those matching cases.

Welcome - BC::ExpectedError, it's just ancestor of BC::Ext::Refined and by default it maps the context to Tram::Policy::Errors.

```ruby
module RubygemsAPI
  class PlainTextError < BC::ExpectedError
    def match
      @context[:parsed] ||= JSON.parse(value)
    rescue JSON::ParserError
      @context[:plain_text] = value.to_s
      self
    end
  end

  class JsonType < BC::Ext::Refined
    def match
      @context[:parsed] ||= JSON.parse(value)
      self
    end

    def mapped
      @context[:parsed]
    end
  end

  Response = JsonType.or_a(PlainTextError)
end

RubygemsAPI::Response.match('{"project": ...}') # => #<JsonType ...>

match = RubygemsAPI::Response.match('Project not found!') # => #<PlainTextError ...>

# translation key: en.contracts.rubygems_api/plain_text_error.message
match.unpack # => "Service responded with a message: `Project not found!`"
```

### Summary

That covers all the relevant scenarios for types and contract validations.
If you have a case that is not covered and you find it useful - feel free to [open an Issue](https://github.com/sclinede/blood_contracts-ext/issues/new)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sclinede/blood_contracts-ext. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BloodContracts::Ext project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/sclinede/blood_contracts-ext/blob/master/CODE_OF_CONDUCT.md).
