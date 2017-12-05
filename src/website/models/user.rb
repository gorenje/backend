class User < ActiveRecord::Base
  include ModelHelpers::CredentialsHelper
  has_many :addresses
  has_many :notifications

  def self.find_by_external_id(eid)
    _,p,l,v = Base64::decode64(eid).split(/\|/)
    v =~ /.{#{p.to_i}}(.{#{l.to_i}})/
    find_by_id($1)
  end

  def external_id
    l = id.to_s.length
    p = rand(18-l)+1
    r = ("%020d" % rand.to_s.gsub(/^.+[.]/,'').to_i).
      gsub(/(.{#{p}}).{#{l}}(.+)/, "\\1#{id}\\2")
    Base64::encode64("eid|%03d|%03d|%s" % [p,l,r]).strip
  end

  def userid_for_sendbird
    if has_sendbird_id?
      sendbird_userid
    else
      data = {
        :user_id     => create_sendbird_userid,
        :nickname    => name,
        :profile_url => external_profile_url
      }
      SendbirdApi.new.users.post(data)
      update(:sendbird_userid => data[:user_id])
      data[:user_id]
    end
  end

  def has_sendbird_id?
    !!sendbird_userid
  end

  def notification_callback_url
    "#{$hosthandler.login.url}/notification/#{external_id}"
  end

  def unread_notification_count
    notifications.where(:read_at => nil).count
  end

  def create_sendbird_userid
    "%s_%s" % [email,
               PasswordGenerator.generate_sendbird_user_id(79-email.length)]
  end

  def external_profile_url
    "#{$hosthandler.profile.url}/profile/%s" % external_id
  end

  def gravatar_image
    "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}"
  end

  def login_token=(val)
    self.creds = self.creds.merge("login_token" => val)
  end

  def password=(val)
    self.creds = self.creds.merge("pass_hash" => Digest::SHA512.hexdigest(val))
  end

  def email_confirm_token_matched?(token, slt)
    confirm_token == AdtekioUtilities::Encrypt.generate_sha512(slt, token)
  end

  def to_hash
    JSON.parse(to_json)
  end

  def password_match?(val)
    c = self.creds
    val && c &&
      c["pass_hash"] && Digest::SHA512.hexdigest(val) == c["pass_hash"]
  end

  def generate_email_token(more_args = {})
    {}.tap do |p|
      p[:token]         = AdtekioUtilities::Encrypt.generate_token
      p[:salt]          = AdtekioUtilities::Encrypt.generate_salt
      p[:confirm_token] = AdtekioUtilities::Encrypt.generate_sha512(p[:salt], p[:token])

      # so the encoding of the email isnt always the same
      estr = { :email => email, :salt => p[:salt] }.merge(more_args).to_json
      p[:email] = AdtekioUtilities::Encrypt.encode_to_base64(estr)
    end
  end

  def generate_email_confirmation_link
    params = generate_email_token

    update(:salt             => nil,
           :has_confirmed    => false,
           :confirm_token    => params[:confirm_token])

    "#{$hosthandler.login.url}/user/emailconfirm?%s" % {
      :email => params[:email], :token => params[:token] }.to_query
  end
end
