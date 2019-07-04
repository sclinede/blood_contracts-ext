RSpec.describe BloodContracts::Core::ExpectedError do
  before do
    module Test
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
  end

  subject { Test::Response.match(value) }

  context "when value is a JSON" do
    let(:value) { '{"name": "Andrew", "registered_at": "2019-01-01"}' }
    let(:payload) do
      { "name" => "Andrew", "registered_at" => "2019-01-01" }
    end

    it do
      is_expected.to be_valid
      is_expected.to match(kind_of(Test::JsonType))
      expect(subject.unpack).to match(payload)
    end
  end

  context "when value is a plain text" do
    let(:value) { "Nothing found!" }
    let(:error_messages) do
      ["Service responded with a message: `#{value}`"]
    end

    it do
      is_expected.to be_valid
      expect(subject).to match(kind_of(Test::PlainTextError))
      expect(subject.unpack).to match(kind_of(Tram::Policy::Errors))
      expect(subject.unpack.messages).to match(error_messages)
    end
  end
end
