require 'rails_helper'

describe SmsSenderNumberChangeJob, sms: true do
  let(:user) { build_stubbed(:user, :with_mobile) }

  describe '.perform' do
    it 'sends number change message to user.mobile' do
      SmsSenderNumberChangeJob.perform_now(user.mobile)

      expect(messages.size).to eq(1)
      msg = messages.first
      expect(msg.number).to eq(user.mobile)
      expect(msg.body).to include('You have changed the phone number')
    end
  end
end
