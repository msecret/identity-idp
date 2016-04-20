include ActionView::Helpers::DateHelper

UserDecorator = Struct.new(:user) do
  def lockout_time_remaining
    (Devise.allowed_otp_drift_seconds - (Time.zone.now - user.second_factor_locked_at)).to_i
  end

  def lockout_time_remaining_in_words
    distance_of_time_in_words(
      Time.zone.now, Time.zone.now + lockout_time_remaining, true, highest_measures: 2)
  end

  def confirmation_period_expired_error
    I18n.t('errors.messages.confirmation_period_expired', period: confirmation_period)
  end

  def confirmation_period
    distance_of_time_in_words(
      Time.zone.now, Time.zone.now + Devise.confirm_within, true, accumulate_on: :hours)
  end

  def first_sentence_for_confirmation_email
    if user.reset_requested_at
      'Your Upaya account has been reset by a tech support representative. ' \
      'In order to continue, you must confirm your email address.'
    else
      "To finish #{user.confirmed_at ? 'updating' : 'creating'} your " \
      'Upaya Account, you must confirm your email address.'
    end
  end

  def needs_account_type?
    user.account_type.nil? && user.ial_token.nil?
  end

  def mobile_change_requested?
    user.unconfirmed_mobile.present? && user.mobile.present?
  end

  def qrcode
    issuer = Rails.application.class.parent_name
    options = {issuer: issuer}
    url = user.provisioning_uri(nil, options)
    puts "XXXXXXX URL = " + url
    qrcode = RQRCode::QRCode.new(url)
    qrcode.as_png(size: 166).to_data_url
  end
end
