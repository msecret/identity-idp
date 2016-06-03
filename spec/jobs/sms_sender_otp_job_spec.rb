require 'rails_helper'

describe SmsSenderOtpJob, sms: true do
  let(:user) { build_stubbed(:user, :with_mobile, direct_otp: '12345') }

  describe '.perform' do
    context 'when the user has a mobile number and no unconfirmed number' do
      it 'sends OTP message to the confirmed number' do
        SmsSenderOtpJob.perform_now(user)

        expect(messages.size).to eq(1)
        msg = messages.first
        expect(msg.number).to eq(user.mobile)
        expect(msg.body).to include('secure one-time password')
        expect(msg.body).to include('12345')
      end
    end

    context 'when the user has a mobile number and an unconfirmed number' do
      it 'sends OTP message to the unconfirmed number' do
        user = build_stubbed(
          :user,
          :with_mobile,
          direct_otp: '12345',
          unconfirmed_mobile: '7035551212'
        )

        SmsSenderOtpJob.perform_now(user)

        expect(messages.size).to eq(1)
        msg = messages.first
        expect(msg.number).to eq('7035551212')
        expect(msg.body).to include('secure one-time password')
        expect(msg.body).to include('12345')
      end
    end

    context 'when the user only has an unconfirmed number' do
      it 'sends OTP message to the unconfirmed number' do
        user = build_stubbed(
          :user,
          direct_otp: '12345',
          unconfirmed_mobile: '7035551212'
        )

        SmsSenderOtpJob.perform_now(user)

        expect(messages.size).to eq(1)
        msg = messages.first
        expect(msg.number).to eq('7035551212')
        expect(msg.body).to include('secure one-time password')
        expect(msg.body).to include('12345')
      end
    end
  end
end
