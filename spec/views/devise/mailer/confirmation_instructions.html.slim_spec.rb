require 'rails_helper'

describe 'devise/mailer/confirmation_instructions.html.slim' do
  it 'mentions how long the user has to confirm' do
    user = build_stubbed(:user, confirmed_at: Time.zone.now)
    assign(:resource, user)
    assign(:confirmation_period, UserDecorator.new(user).confirmation_period)
    render

    expect(rendered).to have_content 'Please note that this confirmation link expires in 24 hours'
  end

  it 'includes a link to Upaya' do
    assign(:resource, build_stubbed(:user, confirmed_at: Time.zone.now))
    render

    expect(rendered).to have_link(
      'https://upaya.18f.gov/contact', href: 'https://upaya.18f.gov/contact'
    )
  end

  it 'includes a link to confirmation' do
    assign(:resource, build_stubbed(:user, confirmed_at: Time.zone.now))
    assign(:token, 'foo')
    render

    expect(rendered).to have_link(
      'http://test.host/users/confirmation?confirmation_token=foo',
      href: 'http://test.host/users/confirmation?confirmation_token=foo'
    )
  end

  it 'includes a request to not reply to this messsage' do
    assign(:resource, build_stubbed(:user, confirmed_at: Time.zone.now))
    render

    expect(rendered).to have_content 'PLEASE DO NOT REPLY TO THIS MESSAGE'
  end

  it 'mentions updating an account when user has already been confirmed' do
    user = build_stubbed(:user, confirmed_at: Time.zone.now)
    assign(:resource, user)
    assign(:first_sentence, UserDecorator.new(user).first_sentence_for_confirmation_email)
    render

    expect(rendered).
      to have_content 'To finish updating your Upaya Account, you must confirm your email address.'
  end

  it 'mentions creating an account when user is not yet confirmed' do
    user = build_stubbed(:user, confirmed_at: nil)
    assign(:resource, user)
    assign(:first_sentence, UserDecorator.new(user).first_sentence_for_confirmation_email)
    render

    expect(rendered).
      to have_content 'To finish creating your Upaya Account, you must confirm your email address.'
  end

  it 'mentions resetting the account when account has been reset by tech support' do
    user = build_stubbed(:user, reset_requested_at: Time.zone.now)
    assign(:resource, user)
    assign(:first_sentence, UserDecorator.new(user).first_sentence_for_confirmation_email)
    render

    expect(rendered).
      to have_content 'Your Upaya account has been reset by a tech support representative'

    expect(rendered).
      to_not have_content 'To finish creating Your Upaya account'

    expect(rendered).
      to_not have_content 'To finish updating Your Upaya account'
  end
end
