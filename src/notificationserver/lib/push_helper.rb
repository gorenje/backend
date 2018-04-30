module PushHelper
  extend self

  class PushNotification
    attr_reader :url, :msg, :locale, :title, :data

    def initialize(url, msg)
      @msg    = msg
      @url    = url
      @locale = nil
      @title  = nil
      @data   = {}
    end

    def localize(mapping)
      self
    end
  end

  class PushNotificationLocaliziable < PushNotification
    def initialize(url, params)
      super(url, nil)
      @params = params
      @data   = params[:data] || {}
    end

    def locale_for(mapping)
      (mapping.locale &&
       if I18n.available_locales.include?(mapping.locale.to_sym)
         mapping.locale
       elsif I18n.available_locales.include?(mapping.locale[0..1].to_sym)
         mapping.locale[0..1]
       end) || I18n.default_locale
    end

    def localize(mapping)
      [:offer, :search].each do |param_name|
        if @params[param_name].is_a?(OpenStruct)
          JSON(@params[param_name].to_json)["table"].keys.each do |key|
            @params.merge!(:"#{param_name}_#{key}" =>
                           @params[param_name].send(key))
          end
        end
      end

      @locale = locale_for(mapping).to_s
      params  = @params.merge(:locale => locale)
      i18n    = TranslatorHelper.new("notification")
      @msg    = i18n.message.send(@params[:key], params).t
      @title  = i18n.title.send(@params[:key], params).t

      self
    end
  end

  def new_notification(url, msg_or_params)
    (msg_or_params.is_a?(Hash) ?
     PushNotificationLocaliziable : PushNotification).new(url, msg_or_params)
  end

  def open_chat(chat_name, chat_id, msg)
    url = "pushtech://chat/#{chat_name}/open/#{chat_id}"
    params = {
      :key => :new_chat_message, :chat_message => msg, :data => {
        "chat_name" => chat_name,
        "chat_id"   => chat_id
      }
    }
    new_notification(url, params)
  end

  def open_search(search, offer)
    url = "pushtech://search/#{search.id}/#{offer.id}/matched"
    params = {
      :key => :search_matched_offer, :offer => offer, :search => search,
      :data => {
        "search_id"        => search.id,
        "search_device_id" => search.device_id,
        "search_title"     => search.title,
        "offer_id"         => offer.id,
        "offer_device_id"  => offer.device_id,
        "offer_title"      => offer.title,
      }
    }
    new_notification(url, params)
  end

  def open_offer(offer, search)
    url = "pushtech://offer/#{offer.id}/#{search.id}/matched"
    params = {
      :key => :offer_matched_search, :offer => offer, :search => search,
      :data => {
        "search_id"        => search.id,
        "search_device_id" => search.device_id,
        "search_title"     => search.title,
        "offer_id"         => offer.id,
        "offer_device_id"  => offer.device_id,
        "offer_title"      => offer.title,
      }
    }
    new_notification(url, params)
  end
end
