require 'rails_helper'

describe UpdateUserProfileForm do
  let(:user) { build_stubbed(:user, :signed_up) }
  subject { UpdateUserProfileForm.new(user) }

  it do
    is_expected.
      to validate_presence_of(:mobile).
      with_message(t('errors.messages.improbable_phone'))
  end

  it do
    is_expected.
      to validate_presence_of(:current_password).
      with_message("can't be blank")
  end

  it do
    is_expected.to validate_confirmation_of(:password)
  end

  it do
    is_expected.to validate_length_of(:password).
      is_at_least(Devise.password_length.first)
  end

  it do
    is_expected.to validate_length_of(:password).
      is_at_most(Devise.password_length.last)
  end

  it do
    is_expected.to allow_value('ValidPassword1!').for(:password)
  end

  it do
    is_expected.to allow_value('ValidPassword1').for(:password)
  end

  it do
    is_expected.to allow_value('validpassword1!').for(:password)
  end

  it do
    is_expected.to allow_value('VALIDPASSWORD1!').for(:password)
  end

  it do
    is_expected.to allow_value('ValidPASSWORD!').for(:password)
  end

  it do
    is_expected.to allow_value('bear bull bat baboon').for(:password)
  end

  describe 'email validation' do
    it 'uses the valid_email gem with mx and ban_disposable options' do
      email_validator = subject._validators.values.flatten.
                        detect { |v| v.class == EmailValidator }

      expect(email_validator.options).
        to eq(mx: true, ban_disposable_email: true)
    end
  end

  describe 'mobile validation' do
    it 'uses the phony_rails gem with country option set to US' do
      mobile_validator = subject._validators.values.flatten.
                         detect { |v| v.class == PhonyPlausibleValidator }

      expect(mobile_validator.options).
        to eq(country_code: 'US', presence: true, message: :improbable_phone)
    end
  end

  def format_phone(mobile)
    mobile.phony_formatted(
      format: :international, normalize: :US, spaces: ' '
    )
  end

  describe 'password presence' do
    context 'when password is empty' do
      it 'does not require its presence' do
        subject.mobile = format_phone(user.mobile)
        subject.email = user.email
        subject.current_password = user.password

        expect(subject.valid?).to be true
      end
    end
  end

  describe 'email uniqueness' do
    context 'when email is already taken' do
      it 'is invalid' do
        second_user = build_stubbed(:user, :signed_up, email: 'taken@gmail.com')
        allow(User).to receive(:exists?).with(email: second_user.email).and_return(true)

        subject.mobile = format_phone(user.mobile)
        subject.email = second_user.email
        subject.current_password = user.password

        expect(subject.valid_form?).to be false
      end
    end

    context 'when email is not already taken' do
      it 'is valid' do
        subject.mobile = format_phone(user.mobile)
        subject.email = 'not_taken@gmail.com'
        subject.current_password = user.password

        expect(subject.valid_form?).to be true
      end
    end

    context 'when email is same as current user' do
      it 'is valid' do
        subject.mobile = format_phone(user.mobile)
        subject.email = user.email
        subject.current_password = user.password

        expect(subject.valid_form?).to be true
      end
    end

    context 'when email is nil' do
      it 'does not add already taken errors' do
        subject.email = nil

        expect(subject.valid_form?).to be false
        expect(subject.errors[:email].uniq).
          to eq [t('valid_email.validations.email.invalid')]
      end
    end
  end

  describe 'mobile uniqueness' do
    context 'when mobile is already taken' do
      it 'is invalid' do
        second_user = build_stubbed(:user, :signed_up, mobile: '+1 (202) 555-1213')
        allow(User).to receive(:exists?).with(email: 'new@gmail.com').and_return(false)
        allow(User).to receive(:exists?).with(mobile: second_user.mobile).and_return(true)

        subject.email = 'new@gmail.com'
        subject.mobile = second_user.mobile
        subject.current_password = user.password

        expect(subject.valid_form?).to be false
      end
    end

    context 'when mobile is not already taken' do
      it 'is valid' do
        subject.mobile = '+1 (703) 555-1212'
        subject.email = 'not_taken@gmail.com'
        subject.current_password = user.password

        expect(subject.valid_form?).to be true
      end
    end

    context 'when mobile is same as current user' do
      it 'is valid' do
        subject.email = user.email
        subject.mobile = user.mobile
        subject.current_password = user.password

        expect(subject.valid_form?).to be true
      end
    end

    context 'when mobile is nil' do
      it 'does not add already taken errors' do
        subject.mobile = nil

        expect(subject.valid_form?).to be false
        expect(subject.errors[:mobile].uniq).
          to eq [t('errors.messages.improbable_phone')]
      end
    end
  end
end
