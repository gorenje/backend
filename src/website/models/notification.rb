class Notification < ActiveRecord::Base
  belongs_to :user

  def unread?
    read_at.nil?
  end

  def mark_as_unread
    update(:read_at => nil)
  end

  def mark_as_read
    update(:read_at => DateTime.now)
  end

  def params
    JSON((payload["params"] || "{}").gsub('=>',':'))
  end

  def offer
    OpenStruct.new(params["offer"]["table"])
  end

  def search
    OpenStruct.new(params["search"]["table"])
  end

  def chat
    OpenStruct.new(:id => "", :title => "")
  end

  def my_object
    if is_offer_matched_search?
      offer
    else
      is_search_matched_offer? ? search : chat
    end
  end

  def kind
    params["key"] || "test_notification"
  end

  def is_offer_matched_search?
    kind == "offer_matched_search"
  end

  def is_search_matched_offer?
    kind == "search_matched_offer"
  end

  def is_chat_message?
    kind == "new_chat_message"
  end

  def chat_channel_url
    payload["url"].split("/").last
  end

  def chat_message
    params["chat_message"]
  end

  def title
    if is_offer_matched_search?
      search.title
    elsif is_search_matched_offer?
      offer.title
    elsif is_chat_message?
      chat_message
    else
      "Test Notification"
    end
  end
end
