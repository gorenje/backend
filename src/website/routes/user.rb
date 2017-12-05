get '/logout' do
  session.delete(:user_id)
  redirect '/'
end

get '/users/email-confirmation' do
  session[:message] = I18n.t("pages.confirmation.#{params[:r]}")
  haml :"admin/email_confirmation"
end

get '/user/emailconfirm' do
  if params_blank?(:email,:token)
    redirect to_email_confirm("MissingData")
  else
    email, salt = extract_email_and_salt(params[:email])
    if email.blank? or salt.blank?
      redirect to_email_confirm("DataCorrupt")
    end

    user = User.find_by_email(email)
    redirect(to_email_confirm("EmailUnknown")) if user.nil?

    if user.email_confirm_token_matched?(params[:token], salt)
      user.update(:has_confirmed => true, :confirm_token => nil)
      session[:email] = user.email
      session[:message] = I18n.t("pages.register.messages.email_confirmed")
      redirect "/login"
    else
      redirect to_email_confirm("TokenMismatch")
    end
  end
end

get '/user/location' do
  session["latitude"]  = params[:lat]
  session["longitude"] = params[:lng]
  return_json do
    { :status => "ok" }
  end
end

get '/user/addresses' do
  @user = User.find(session[:user_id])
  haml :"user/addresses"
end

get '/user/offers' do
  @user = User.find(session[:user_id])
  haml :"user/offers"
end

get '/user/searches' do
  @user = User.find(session[:user_id])
  haml :"user/searches"
end

get '/user/notifications' do
  @user = User.find(session[:user_id])
  @notifications = @user.notifications.sort_by(&:created_at).reverse
  haml :"user/notifications"
end
