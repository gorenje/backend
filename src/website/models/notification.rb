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

  def offer
    OpenStruct.new(eval(payload["params"])["offer"]["table"])
  end

  def search
    OpenStruct.new(eval(payload["params"])["search"]["table"])
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
    eval(payload["params"])["key"]
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
    eval(payload["params"])["chat_message"]
  end

  def title
    if is_offer_matched_search?
      search.title
    elsif is_search_matched_offer?
      offer.title
    else
      chat_message
    end
  end
end
