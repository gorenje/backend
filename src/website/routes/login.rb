get '/login' do
  @email = session.delete(:email)
  haml :login
end

get '/register' do
  haml :"admin/register"
end

get '/resend/email/:eid' do
  i18n = TranslatorHelper.new("pages.confirmation")
  msg = if user = User.find_by_external_id(params[:eid])
          unless user.has_confirmed?
            Mailer::Client.new.
              send_confirm_email({"confirm_link" =>
                                   user.generate_email_confirmation_link,
                                   "email"     => user.email,
                                   "firstname" => user.name,
                                   "lastname"  => ""})
            i18n.email_resent.t
          else
            i18n.email_already_confirmed.t
          end
        else
          i18n.user_unknown.t
        end

  session[:message] = msg
  haml :"admin/email_confirmation"
end

post '/login' do
  key = OpenSSL::PKey::RSA.new(ENV['RSA_PRIVATE_KEY'].gsub(/\\n/,"\n"))
  data = JSON(JWE.decrypt(params[:creds], key))

  case data["type"]
  when "register"
    i18n = TranslatorHelper.new("pages.register.messages")

    if data["email"].blank?
      @name = data["name"]
      session[:message] = i18n.email_empty.t
    elsif data["password1"].blank? || data["password2"].blank?
      @email = data["email"]
      @name = data["name"]
      session[:message] = i18n.password_blank.t
    elsif u = User.where(:email => data["email"].downcase).first
      session[:message] =
        if u.has_confirmed?
          i18n.email_already_registered_login.t
        else
          i18n.email_already_registered_not_confirmed(:external_id =>
                                                      u.external_id).t
        end
      @email = data["email"]
      @name = data["name"]
    else
      if data["password1"] != data["password2"]
        session[:message] = i18n.password_not_matched.t
        @email = data["email"]
        @name = data["name"]
      else
        u = User.create(:email => data["email"].downcase, :name => data["name"])
        u.password = data["password1"]
        Mailer::Client.new.
          send_confirm_email({"confirm_link" =>
                               u.generate_email_confirmation_link,
                               "email"     => u.email,
                               "firstname" => u.name,
                               "lastname"  => ""})
        session[:message] = i18n.email_confirmation_sent.t
      end
    end
    haml :"admin/register"

  when "login"
    i18n = TranslatorHelper.new("pages.login")
    tstr = if user = User.where(:email => data["email"].downcase).first
             if user.has_confirmed?
               if user.password_match?(data["password"])
                 session[:user_id] = user.id
                 redirect "/searches"
               else
                 @email = data["email"]
                 i18n.email_or_password_wrong.t
               end
             else
               @email = data["email"]
               i18n.email_not_confirmed.t
             end
           else
             @email = data["email"]
             i18n.email_or_password_wrong.t
           end

    session[:message] = tstr
    haml :login
  else
    session[:message] = I18n.t("server.message.unknown_interaction")
    haml :login
  end
end
