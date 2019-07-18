RSpec.describe BloodContracts::Core::MapValue do
  before do
    module Test
      require "forwardable"

      class JsonMapper
        def self.call(**payload)
          JSON.pretty_generate(payload)
        end
      end

      class ContactType < ::BC::Ext::Refined
        extend Forwardable
        extract :name
        extract :phone

        def_delegators :@value, :name, :phone
      end

      class ContactWithManagerType < ContactType
        extract :manager_id

        def manager_id
          value.manager_id
        end
      end

      ContactJsonType =
        ContactWithManagerType.and_then(BC::MapValue.with(JsonMapper))
      Contact = Struct.new(:name, :phone, :manager_id)
    end
  end

  subject { Test::ContactJsonType.match(value) }

  context "when value is a valid contact" do
    let(:value) { Test::Contact.new("Nick Cage", "2-333-111-444", 4113) }
    let(:valid_json) do
      <<~JSON.strip
        {
          "name": "Nick Cage",
          "phone": "2-333-111-444",
          "manager_id": 4113
        }
      JSON
    end

    it do
      is_expected.to be_valid
      expect(subject.unpack).to eq(valid_json)
    end
  end

  context "when value is an invalid contact" do
    let(:value) { "Nick Cage, 2-333-111-444, 4113" }

    it do
      is_expected.to be_invalid
      is_expected.to match(kind_of(::BC::ExceptionCaught))
    end
  end
end
