RSpec.describe "BC::Ext::Refined validation delegated to Tram::Policy" do
  before do
    module Test
      class AddressPolicy < Tram::Policy
        option :country_code
        option :city
        option :street

        validate :city_correctness
        validate :country_code_correctness
        validate :street_correctness

        def country_code_correctness
          return if country_code.to_s.size == 2
          errors.add :invalid_country_code, value: country_code
        end

        def city_correctness
          return if (2..30).cover?(city.to_s.size)
          errors.add :invalid_city_name, value: city
        end

        def street_correctness
          return if (5..75).cover?(street.to_s.size)
          errors.add :invalid_street, value: street
        end
      end

      class AddressType < BC::Ext::Refined
        self.policy = AddressPolicy

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
    end
  end

  subject { Test::AddressType.match(value) }

  context "when input is valid address" do
    let(:mapped_data) do
      { city: "Moscow", country_code: "RU", street: "ul. Novoslobodskaya" }
    end

    context "when value is an Test::Address" do
      let(:value) do
        Test::Address.new("RU", "Moscow", "ul. Novoslobodskaya")
      end

      it do
        expect(subject).to be_valid
        expect(subject).to be_kind_of(Test::AddressType)
        expect(subject.unpack).to match(mapped_data)
      end
    end

    context "when value is a parsed json" do
      let(:json) do
        '{"CountryCode": "RU", '\
        '"City": "Moscow", '\
        '"StreetLine": "ul. Novoslobodskaya"}'
      end
      let(:value) { JSON.parse(json) }

      it do
        expect(subject).to be_valid
        expect(subject).to be_kind_of(Test::AddressType)
        expect(subject.unpack).to match(mapped_data)
      end
    end
  end

  context "when input is invalid address" do
    let(:mapped_data) do
      { Test::AddressType => [kind_of(Tram::Policy::Errors)] }
    end
    let(:error_messages) do
      ["The value `M` is not a valid city name",
       "The value `RUS` is not a valid ISO country code",
       "The value `ul` is not a valid street"]
    end

    context "when value is an Test::Address" do
      let(:value) { Test::Address.new("RUS", "M", "ul") }

      it do
        expect(subject).to be_invalid
        expect(subject).to be_kind_of(BC::PolicyFailure)
        expect(subject.unpack).to match(mapped_data)
        expect(subject.messages).to match(error_messages)
      end
    end

    context "when value is a parsed json" do
      let(:json) { '{"country": "RUS", "city": "M", "street": "ul"}' }
      let(:value) { JSON.parse(json) }

      it do
        expect(subject).to be_invalid
        expect(subject).to be_kind_of(BC::PolicyFailure)
        expect(subject.unpack).to match(mapped_data)
        expect(subject.messages).to match(error_messages)
      end
    end
  end
end
