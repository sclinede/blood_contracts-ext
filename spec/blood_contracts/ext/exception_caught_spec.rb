RSpec.describe BloodContracts::Core::ExceptionCaught do
  before do
    module Test
      class JsonType < BC::Refined
        prepend BC::ExceptionHandling

        def match
          @context[:json_type_input] = value
          @context[:parsed_json] = JSON.parse(@context[:json_type_input])
          self
        end
      end
    end
  end

  subject { Test::JsonType.match(value) }

  context "when value is valid" do
    let(:value) { '{"some": "thing"}' }
    let(:payload) { { "some" => "thing" } }

    it do
      is_expected.to be_valid
      expect(subject.context[:json_type_input]).to eq(value)
      expect(subject.context[:parsed_json]).to match(payload)
    end
  end

  context "when value is invalid" do
    context "when value is a String" do
      let(:value) { "nope, I'm not a JSON" }

      it do
        is_expected.to be_invalid
        expect(subject.context[:json_type_input]).to eq(value)
        expect(subject.exception).to match(kind_of(JSON::ParserError))
      end
    end

    context "when value is a arbitrary object" do
      let(:value) { Class.new }

      it do
        is_expected.to be_invalid
        expect(subject.context[:json_type_input]).to eq(value)
        expect(subject.exception).to match(kind_of(TypeError))
      end
    end
  end
end
