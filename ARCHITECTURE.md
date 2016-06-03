## Architecture

### High-level overview
![Draft Architecture](http://anony.ws/i/2016/05/10/draft-architecture-overviewae85b.png)

The current service-level architecture is comprised of Service Providers, the Government Identity Provider, and the ability to delegate authentication to external Identity Providers. The Government IdP also handles account management. 

* The current counter fraud components are related to prevention of bad requests and activities with automated reporting.


#### Application architecture
![Draft application architecture](http://anony.ws/i/2016/06/03/draft-application-architecture.png)

### SAML Profile
[Web SSO Profile](SAML_PROFILE.md)


### Routes
```
                                    Prefix Verb            URI Pattern                                            Controller#Action
                               sidekiq_web                 /sidekiq                                               Sidekiq::Web
                           dashboard_index GET             /dashboard(.:format)                                   dashboard#index
                   user_omniauth_authorize GET|POST        /users/auth/:provider(.:format)                        users/omniauth_callbacks#passthru {:provider=>/saml/}
                    user_omniauth_callback GET|POST        /users/auth/:action/callback(.:format)                 users/omniauth_callbacks#(?-mix:saml)
                             user_password POST            /users/password(.:format)                              users/passwords#create
                         new_user_password GET             /users/password/new(.:format)                          users/passwords#new
                        edit_user_password GET             /users/password/edit(.:format)                         users/passwords#edit
                                           PATCH           /users/password(.:format)                              users/passwords#update
                                           PUT             /users/password(.:format)                              users/passwords#update
                  cancel_user_registration GET             /users/cancel(.:format)                                users/registrations#cancel
                         user_registration POST            /users(.:format)                                       users/registrations#create
                     new_user_registration GET             /users/sign_up(.:format)                               users/registrations#new
                    edit_user_registration GET             /users/edit(.:format)                                  users/registrations#edit
                                           PATCH           /users(.:format)                                       users/registrations#update
                                           PUT             /users(.:format)                                       users/registrations#update
                                           DELETE          /users(.:format)                                       users/registrations#destroy
                         user_confirmation POST            /users/confirmation(.:format)                          users/confirmations#create
                     new_user_confirmation GET             /users/confirmation/new(.:format)                      users/confirmations#new
                                           GET             /users/confirmation(.:format)                          users/confirmations#show
                     user_password_expired GET             /users/password_expired(.:format)                      devise/password_expired#show
                                           PATCH           /users/password_expired(.:format)                      devise/password_expired#update
                                           PUT             /users/password_expired(.:format)                      devise/password_expired#update
resend_code_user_two_factor_authentication GET             /users/two_factor_authentication/resend_code(.:format) devise/two_factor_authentication#resend_code
            user_two_factor_authentication GET             /users/two_factor_authentication(.:format)             devise/two_factor_authentication#show
                                           PATCH           /users/two_factor_authentication(.:format)             devise/two_factor_authentication#update
                                           PUT             /users/two_factor_authentication(.:format)             devise/two_factor_authentication#update
                          new_user_session GET             /                                                      users/sessions#new
                              user_session POST            /                                                      users/sessions#create
                                    active GET             /active(.:format)                                      users/sessions#active
                                   timeout GET             /timeout(.:format)                                     users/sessions#timeout
                                 user_root GET             /dashboard(.:format)                                   dashboard#index
                                   confirm PATCH           /confirm(.:format)                                     users/confirmations#confirm
                                 users_otp GET             /users/otp(.:format)                                   devise/two_factor_authentication_setup#index
                                           PATCH           /users/otp(.:format)                                   devise/two_factor_authentication_setup#set
                             users_otp_new GET             /users/otp/new(.:format)                               devise/two_factor_authentication#new
                             api_saml_auth GET|POST        /api/saml/auth(.:format)                               saml_idp#auth
                         api_saml_metadata GET             /api/saml/metadata(.:format)                           saml_idp#metadata
                      destroy_user_session GET|POST|DELETE /api/saml/logout(.:format)                             saml_idp#logout
                                      root GET             /                                                      users/sessions#new
```
