class TwilioService
  def initialize
    return null_twilio_client if FeatureManagement.pt_mode?
    return twilio_proxy_client if proxy_addr.present?
    twilio_client
  end

  def account
    @account ||= random_account
  end

  def send_sms(params = {})
    params = params.reverse_merge(from: from_number)
    @client.messages.create(params)
  end

  private

  def proxy_addr
    Figaro.env.proxy_addr
  end

  def proxy_port
    Figaro.env.proxy_port
  end

  def null_twilio_client
    @client ||= NullTwilioClient.new
  end

  def twilio_proxy_client
    @client ||= Twilio::REST::Client.new(
      account['sid'],
      account['auth_token'],
      proxy_addr: proxy_addr,
      proxy_port: proxy_port
    )
  end

  def twilio_client
    @client ||= Twilio::REST::Client.new(
      account['sid'],
      account['auth_token']
    )
  end

  def from_number
    "+1#{account['number']}"
  end

  def random_account
    TWILIO_ACCOUNTS.sample
  end
end
