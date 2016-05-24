require 'rails_helper'

include SamlAuthHelper
include SamlResponseHelper

feature 'saml api', devise: true, sms: true do
  let(:user) { create(:user, :signed_up) }

  context 'Unencrypted SAML Assertions' do
    context 'before fully signing in' do
      before { visit authnrequest_get }

      it 'prompts the user to sign in' do
        expect(page).to have_content I18n.t 'devise.failure.unauthenticated'
      end

      it 'prompts the user to enter OTP' do
        sign_in_user(user)
        expect(page).to have_content I18n.t('devise.two_factor_authentication.header_text')
      end
    end

    context 'user has not set up 2FA yet and signs in' do
      let(:user) { create(:user) }

      before { visit authnrequest_get }

      it 'prompts the user to set up 2FA' do
        sign_in_user(user)

        expect(current_path).to eq users_otp_path
      end

      it 'prompts the user to enter OTP after setting up 2FA' do
        sign_in_user(user)

        fill_in 'Mobile', with: '202-555-1212'
        click_button 'Submit'

        expect(current_path).to eq user_two_factor_authentication_path
      end
    end

    context 'first time registration' do
      before { visit authnrequest_get }

      it 'prompts user to set up 2FA after confirming email and setting password' do
        sign_up_with_and_set_password_for('user@example.com')

        expect(current_path).to eq users_otp_path
      end

      it 'prompts the user to enter OTP after setting up 2FA' do
        sign_up_with_and_set_password_for('user@example.com')

        fill_in 'Mobile', with: '202-555-1212'
        click_button 'Submit'

        expect(current_path).to eq user_two_factor_authentication_path
      end
    end

    context 'user can get a well-formed signed Assertion' do
      before do
        visit authnrequest_get
        authenticate_user(user)
      end

      let(:xmldoc) { XmlDoc.new('feature', 'response_assertion') }

      it 'renders saml_post_binding template with XML response' do
        expect(page.find('#SAMLResponse', visible: false)).to be_truthy
      end

      it 'contains an assertion nodeset' do
        expect(xmldoc.response_assertion_nodeset.length).to eq(1)
      end

      it 'populates issuer with the idp name' do
        expect(xmldoc.issuer_nodeset.length).to eq(1)
        expect(xmldoc.issuer_nodeset[0].content).to eq("https://#{Figaro.env.domain_name}/api/saml")
      end

      it 'signs the assertion' do
        expect(xmldoc.signature_nodeset.length).to eq(1)
      end

      it 'applies xmldsig enveloped signature correctly' do
        skip
        # Verify
        #   http://www.w3.org/2000/09/xmldsig#enveloped-signature
      end

      it 'applies canonicalization method correctly' do
        skip
        # Verify
        #   http://www.w3.org/2001/10/xml-exc-c14n#
      end

      it 'contains a signature method nodeset with SHA256 algorithm' do
        expect(xmldoc.signature_method_nodeset.length).to eq(1)
        expect(xmldoc.signature_method_nodeset[0].attr('Algorithm')).
          to eq('http://www.w3.org/2001/04/xmldsig-more#rsa-sha256')
      end

      it 'redirects to /test/saml/decode_assertion after submitting the form' do
        click_button 'Submit'
        expect(page.current_url).
          to eq(saml_spec_settings.assertion_consumer_service_url)
      end

      it 'stores SP identifier in Identity model' do
        expect(user.last_identity.service_provider).to eq saml_spec_settings.issuer
      end

      it 'stores authn_context in Identity model' do
        expect(user.last_identity.authn_context).to eq saml_settings.authn_context
      end

      it 'stores last_authenticated_at in Identity model' do
        expect(user.last_identity.last_authenticated_at).to be_present
      end

      it 'disables cache' do
        expect(page.response_headers['Pragma']).to eq 'no-cache'
      end

      it 'stores provider and authn_context in session' do
        session_hash =
          {
            provider: saml_spec_settings.issuer,
            authn_context: saml_settings.authn_context
          }

        expect(page.get_rack_session_key('sp_data')).to eq(session_hash)
      end

      it 'retains the formatting of the mobile number' do
        expect(xmldoc.mobile_number.children.children.to_s).to eq(user.mobile)
      end
    end
  end

  context 'visiting /test/saml' do
    scenario 'it requires 2FA' do
      visit '/test/saml'
      sign_in_user
      expect(current_path).to eq(users_otp_path)
      expect(page).to have_content(I18n.t('devise.two_factor_authentication.otp_setup'))
    end

    it 'adds unique ACS and ACLS URLs for current Rails env to CSP form_action' do
      # ACS = acs_url, ACLS = assertion_consumer_logout_service_url
      visit '/test/saml'
      authenticate_user(user)

      expect(page.response_headers['Content-Security-Policy']).
        to include(
          'form-action \'self\' localhost:3000/test/saml/decode_assertion ' \
          'example.com/test/saml/decode_assertion ' \
          'localhost:3000/test/saml/decode_slo_request ' \
          'example.com/test/saml/decode_slo_request;')
    end
  end

  context 'visiting /api/saml/logout' do
    context 'when logged in to single SP with IdP-initiated logout' do
      let(:user) { create(:user, :signed_up) }
      let(:xmldoc) { XmlDoc.new('feature', 'request_assertion') }
      let(:response_xmldoc) { XmlDoc.new('feature', 'response_assertion') }

      before do
        visit sp1_authnrequest
        authenticate_user(user)

        @asserted_session_index = response_xmldoc.assertion_statement_node['SessionIndex']
        visit destroy_user_session_url
      end

      it 'successfully logs the user out' do
        click_button 'Submit'
        expect(page).to have_content t('devise.sessions.signed_out')
      end

      it 'generates a signed LogoutRequest' do
        expect(xmldoc.request_assertion).to_not be_nil
      end

      it 'references the correct SessionIndex' do
        expect(xmldoc.logout_asserted_session_index).to eq(@asserted_session_index)
      end

      it 'generates logout request with Issuer' do
        expect(xmldoc.issuer_nodeset.length).to eq(1)
        expect(xmldoc.issuer_nodeset[0].content).to eq "https://#{Figaro.env.domain_name}/api/saml"
      end
    end

    context 'when logged in to a single SP with SP-initiated logout' do
      let(:user) { create(:user, :signed_up) }
      let(:xmldoc) { XmlDoc.new('feature', 'logout_assertion') }

      before do
        visit sp1_authnrequest
        authenticate_user(user)

        request = OneLogin::RubySaml::Logoutrequest.new
        settings = sp1_saml_settings
        settings.name_identifier_value = user.uuid

        visit request.create(settings)
      end

      it 'signs out the user from IdP' do
        expect(user.current_sign_in_at).to be_nil

        visit edit_user_registration_path

        expect(page).to have_content I18n.t 'devise.failure.unauthenticated'
      end

      it 'contains an issuer nodeset' do
        expect(xmldoc.issuer_nodeset.length).to eq(1)
        expect(xmldoc.issuer_nodeset[0].content).to eq "https://#{Figaro.env.domain_name}/api/saml"
      end

      it 'contains a signature nodeset' do
        expect(xmldoc.signature_nodeset.length).to eq(1)
      end

      it 'contains a signature method nodeset with SHA256 algorithm' do
        expect(xmldoc.signature_method_nodeset.length).to eq(1)
        expect(xmldoc.signature_method_nodeset[0].attr('Algorithm')).
          to eq('http://www.w3.org/2001/04/xmldsig-more#rsa-sha256')
      end

      it 'contains a digest method nodeset with SHA256 algorithm' do
        expect(xmldoc.digest_method_nodeset.length).to eq(1)
        expect(xmldoc.digest_method_nodeset[0].attr('Algorithm')).
          to eq('http://www.w3.org/2001/04/xmlenc#sha256')
      end

      it 'returns a SAMLResponse' do
        expect(page.find('#SAMLResponse', visible: false)).to be_truthy
      end

      it 'disables cache' do
        expect(page.response_headers['Pragma']).to eq 'no-cache'
      end

      it 'deactivates the identity' do
        expect(user.active_identities.size).to eq(0)
      end
    end

    context 'with authentication at a SP and session times out' do
      let(:logout_user) { create(:user, :signed_up) }

      before do
        visit sp1_authnrequest
        authenticate_user(logout_user)
      end

      it 'redirects to root' do
        Timecop.travel(Devise.timeout_in + 1.second)
        visit destroy_user_session_url
        expect(page.current_path).to eq('/')
        Timecop.return
      end
    end

    context 'without SLO implemented at SP' do
      let(:logout_user) { create(:user, :signed_up) }

      before do
        visit sp1_authnrequest
        authenticate_user(logout_user)
      end

      it 'completes logout at IdP' do
        allow_any_instance_of(ServiceProvider).to receive(:metadata).and_return(
          {
             service_provider: "https://rp1.serviceprovider.com/auth/saml/metadata",
             authn_context: "http://idmanagement.gov/ns/assurance/loa/1",
             last_authenticated_at: "2016-05-24 16:29:25",
             user_id: 1,
             created_at: "2016-05-24 16:29:25",
             updated_at: "2016-05-24 16:29:25",
             session_index: 1,
             session_uuid: "_7672a58d-eee4-42fd-8e15-1c04d1ef3340",
             quiz_started: false
          })

        visit destroy_user_session_url

        expect(page.current_path).to eq('/')
      end
    end
  end
end
