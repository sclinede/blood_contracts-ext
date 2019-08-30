RSpec.describe BloodContracts::Core::PolicyFailure do
  before do
    module Test
      class Phone < ::BC::Ext::Refined
        REGEX = /\A(\+7|8)(9|8)\d{9}\z/i

        def match
          context[:phone_input] = value.to_s
          clean_phone = context[:phone_input].gsub(/[\s\(\)-]/, "")
          return failure(:invalid_phone) if clean_phone !~ REGEX
          context[:clean_phone] = clean_phone

          self
        end

        def mapped
          context[:clean_phone]
        end
      end

      class Email < ::BC::Ext::Refined
        REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
        INVALID_EMAIL = define_error(:invalid_email)

        def match
          context[:email_input] = value.to_s
          return failure(INVALID_EMAIL) if context[:email_input] !~ REGEX
          context[:email] = context[:email_input]

          self
        end

        def mapped
          context[:email]
        end
      end

      class Ascii < ::BC::Ext::Refined
        REGEX = /^[[:ascii:]]+$/i

        def match
          context[:ascii_input] = value.to_s
          return failure("Not ASCII") if context[:ascii_input] !~ REGEX
          context[:ascii] = context[:ascii_input]

          self
        end

        def mapped
          context[:ascii]
        end
      end

      Login = Email.or_a(Phone)
    end
  end

  describe "Errors composition with Tram::Policy::Errors" do
    context "when using `OR` composition" do
      subject { Test::Login.match(value) }

      context "when value is invalid" do
        let(:value) { "tasf" }
        let(:errors_list) do
          [
            { Test::Email => [kind_of(Tram::Policy::Errors)] },
            { Test::Phone => [kind_of(Tram::Policy::Errors)] }
          ]
        end
        let(:policy_errors) do
          [
            kind_of(Tram::Policy::Errors),
            kind_of(Tram::Policy::Errors)
          ]
        end
        let(:validation_context) { { phone_input: value, email_input: value } }
        let(:messages) do
          [
            "Value `tasf` is not a valid phone",
            "Given value is not a valid email"
          ]
        end

        it do
          is_expected.to be_invalid
          expect { subject.unpack }.not_to raise_error
          expect(subject.errors).to match_array(errors_list)
          expect(subject.policy_errors).to match(policy_errors)
          expect(subject.messages).to match_array(messages)
          expect(subject.contexts.reduce(:merge)).to include(validation_context)
        end
      end
    end

    context "when using `AND` composition" do
      subject { Test::RegistrationInput.match(email, phone) }

      before do
        module Test
          class RegistrationInput < ::BC::Ext::Tuple
            attribute :login,    Login
            attribute :password, Ascii
          end
        end
      end

      context "when input is invalid" do
        let(:email) { "admin" }
        let(:phone) { "not_a_phone" }
        let(:login_error) { { Test::Login => [kind_of(Tram::Policy::Errors)] } }
        let(:password) { "newP@ssw0rd" }
        let(:attributes) do
          attribute_errors.merge(password: kind_of(Test::Ascii))
        end
        let(:attribute_errors) do
          {
            login: kind_of(BC::PolicyFailure),
          }
        end
        let(:errors) do
          [
            { Test::Email => [kind_of(Tram::Policy::Errors)] },
            { Test::Phone => [kind_of(Tram::Policy::Errors)] },
          ]
        end
        let(:attribute_messages) do
          {
            login: [
              "Given value is not a valid email",
              "Value `admin` is not a valid phone"
            ],
          }
        end

        it do
          expect(subject).to be_invalid
          expect(subject.attributes).to match(attributes)
          expect(subject.errors).to match_array(errors)
          expect(subject.attribute_errors).to match(attribute_errors)
          expect(subject.attribute_messages).to match(attribute_messages)
        end
      end
    end
  end
end
