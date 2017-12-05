class UrlConfigParser
  attr_reader :event, :params, :user, :netcfg, :postback

  def initialize(event, postback)
    @event    = event
    @params   = NetworkUser::WrapClickData.new(event.params)
    @user     = postback.user_required? ? event.network_user(postback) : nil
    @netcfg   = postback.netcfg
    @postback = postback
  end

  def generate
    AdtekioAdnetworks::Postbacks.networks[postback.network.to_sym].
      new(event, user, netcfg, params).
      send(postback.event, postback.platform).
      map do |hsh|
      hsh.merge!(:pbid => postback.id)
    end
  end
end
