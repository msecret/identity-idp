class SmsSenderOtpJob < ActiveJob::Base
  queue_as :sms

  def perform(user)
    twilio_service = TwilioService.new
    send(:otp, twilio_service, user)
  end

  private

  def otp(twilio_service, user)
    twilio_service.send_sms(
      to: target_number_for(user),
      body: otp_message(user.direct_otp)
    )
  end

  def target_number_for(user)
    UserDecorator.new(user).two_factor_phone_number
  end

  def otp_message(code)
    <<-END.strip_heredoc
      You requested a secure one-time password to log in to your Upaya Account.

      Please enter this secure one-time password: #{code}
    END
  end
end
