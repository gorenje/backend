# encoding: UTF-8
require_relative '../test_helper'

class PushHelperTest < Minitest::Test
  def setup
    offer_string = "%{search_title}"
    chat_string = "%{chat_message}"

    assert_equal [:en,:de], I18n.available_locales
    i18n = TranslatorHelper.new("notification")
    assert_equal(offer_string,
                 i18n.message.send(:offer_matched_search, :locale => :en).t)
    assert_equal(chat_string,
                 i18n.message.send(:new_chat_message, :locale => :en).t)
  end

  context "simple PN" do
    should "return self" do
      obj = PushHelper.new_notification("fubar", "msg")
      assert obj.is_a?(PushHelper::PushNotification)
      assert_equal obj, obj.localize(nil)
    end
  end

  context "matched PN" do
    should "handle chat message" do
      params = {
        :key    => :new_chat_message,
        :chat_message => "Hi there, this is the message"
      }

      obj = PushHelper.new_notification("fubar", params)
      assert obj.is_a?(PushHelper::PushNotificationLocaliziable)
      assert_nil obj.msg

      assert_equal obj, obj.localize(OpenStruct.new(:locale => "en"))
      assert_equal(params[:chat_message],obj.msg)
      assert_equal("Chat Message",obj.title)
    end

    should "obtain the correct locale for offer matched search" do
      params = {
        :key    => :offer_matched_search,
        :offer  => OpenStruct.new(:title => "Offer Title"),
        :search => OpenStruct.new(:title => "Search Title"),
      }

      obj = PushHelper.new_notification("fubar", params)
      assert obj.is_a?(PushHelper::PushNotificationLocaliziable)
      assert_nil obj.msg

      {
        "en" => [nil, "", "en", "en-GB", "en-US", "he", "pt", "pl"],
        "de" => ["de", "de-DE", "de-CH"],
      }.each do |exp_locale, list_of_locales|
        list_of_locales.each do |input_locale|
          assert_equal(exp_locale,
                       obj.locale_for(OpenStruct.
                                      new(:locale => input_locale)).to_s,
                       "Failed for #{input_locale}")
        end
      end

      assert_equal obj, obj.localize(OpenStruct.new(:locale => "en"))
      assert_equal("Search Title", obj.msg)
      assert_equal("Search Found", obj.title)
    end

    should "obtain the correct locale for search matched offer" do
      params = {
        :key    => :search_matched_offer,
        :offer  => OpenStruct.new(:title => "Offer Title"),
        :search => OpenStruct.new(:title => "Search Title"),
      }

      obj = PushHelper.new_notification("fubar", params)
      assert obj.is_a?(PushHelper::PushNotificationLocaliziable)
      assert_nil obj.msg

      assert_equal obj, obj.localize(OpenStruct.new(:locale => "en"))
      assert_equal("Offer Title", obj.msg)
      assert_equal("Offer Found", obj.title)
    end
  end

  context "send to one signal" do
    should "ensure data is not added if empty" do
      tme = Time.now
      mock(Time).now.any_times { tme }

      mock(OneSignal::Notification).
        create({:params=>{"headings"=>{"en"=>"Search Found"},
                          "contents"=>{"en"=>"Search Title"},
                          "content_available"=>true,
                          "include_player_ids"=>["player_id"],
                          "app_id"=>nil,
                          "url"=>"url",
                          "android_group"=>"push",
                          "android_group_message"=>{
                            "en"=>"You have $[notif_count] new messages"},
                          "ios_badgeType"=>"Increase",
                          "ios_badgeCount"=>1,
                          "data"=>{
                            "sent_at"=>tme.utc.strftime("%s%L").to_i
                          }}}) do
        OpenStruct.new({ :body => {:ok => :status}.to_json})
      end

      params = {
        :key    => :offer_matched_search,
        :offer  => OpenStruct.new(:title => "Offer Title"),
        :search => OpenStruct.new(:title => "Search Title"),
      }

      notif = PushHelper.new_notification("url", params)

      r = OneSignalHelper.
        send_message_to_player("player_id",
                               notif.localize(OpenStruct.new(:locale => "en")))
      assert_equal r["ok"], "status"
    end

    should "work for open_chat notifications" do
      tme = Time.now
      mock(Time).now.any_times { tme }

      expected_params =
        { :params => {
            "headings"=>{"en"=>"Chat Message"},
            "contents"=>{"en"=>"Message is Empty"},
            "content_available"=>true,
            "include_player_ids"=>["player_id"],
            "app_id"=>nil,
            "url"=>"pushtech://chat/chat_name/open/chat_id",
            "android_group"=>"push",
            "android_group_message"=>{
              "en"=>"You have $[notif_count] new messages"},
            "ios_badgeType"=>"Increase",
            "ios_badgeCount"=>1,
            "data"=>{
              "sent_at"   => tme.utc.strftime("%s%L").to_i,
              "chat_name" => "chat_name",
              "chat_id"   => "chat_id"
            }
          }
        }

      mock(OneSignal::Notification).
        create(expected_params) do
        OpenStruct.new({ :body => {:ok => :status}.to_json})
      end

      notif = PushHelper.open_chat("chat_name", "chat_id", "Message is Empty")

      r = OneSignalHelper.
        send_message_to_player("player_id",
                               notif.localize(OpenStruct.new(:locale => "en")))
      assert_equal r["ok"], "status"
    end

    should "work for search_matched_offer notifications" do
      tme = Time.now
      mock(Time).now.any_times { tme }

      expected_params = {
        :params => {
          "headings"              => {"en"=>"Offer Found"},
          "contents"              => {"en"=>"Offer Title"},
          "content_available"     => true,
          "include_player_ids"    => ["player_id"],
          "app_id"                => nil,
          "url" => "pushtech://search/search_id/offer_id/matched",
          "android_group"         => "push",
          "android_group_message" => {
            "en" => "You have $[notif_count] new messages"
          },
          "ios_badgeType"         => "Increase",
          "ios_badgeCount"        => 1,
          "data" => {
            "search_id"        => "search_id",
            "search_device_id" => "search_device_id",
            "search_title"     => "Search Title",
            "offer_id"         => "offer_id",
            "offer_device_id"  => "offer_device_id",
            "offer_title"      => "Offer Title",
            "sent_at"          => tme.utc.strftime("%s%L").to_i,
          }
        }
      }

      mock(OneSignal::Notification).
        create(expected_params) do
        OpenStruct.new({ :body => {:ok => :status}.to_json})
      end

      offr = OpenStruct.new(:title     => "Offer Title",
                            :device_id => "offer_device_id",
                            :id        => "offer_id")
      srch = OpenStruct.new(:title     => "Search Title",
                            :device_id => "search_device_id",
                            :id        => "search_id")

      notif = PushHelper.open_search(srch,offr)

      r = OneSignalHelper.
        send_message_to_player("player_id",
                               notif.localize(OpenStruct.new(:locale => "en")))
      assert_equal r["ok"], "status"
    end

    should "work for offer_matched_search notifications" do
      tme = Time.now
      mock(Time).now.any_times { tme }

      expected_params = {
        :params => {
          "headings"              => {"en"=>"Search Found"},
          "contents"              => {"en"=>"Search Title"},
          "content_available"     => true,
          "include_player_ids"    => ["player_id"],
          "app_id"                => nil,
          "url" => "pushtech://offer/offer_id/search_id/matched",
          "android_group"         => "push",
          "android_group_message" => {
            "en" => "You have $[notif_count] new messages"
          },
          "ios_badgeType"         => "Increase",
          "ios_badgeCount"        => 1,
          "data" => {
            "search_id"        => "search_id",
            "search_device_id" => "search_device_id",
            "search_title"     => "Search Title",
            "offer_id"         => "offer_id",
            "offer_device_id"  => "offer_device_id",
            "offer_title"      => "Offer Title",
            "sent_at"          => tme.utc.strftime("%s%L").to_i,
          }
        }
      }

      mock(OneSignal::Notification).
        create(expected_params) do
        OpenStruct.new({ :body => {:ok => :status}.to_json})
      end

      offr = OpenStruct.new(:title     => "Offer Title",
                            :device_id => "offer_device_id",
                            :id        => "offer_id")
      srch = OpenStruct.new(:title     => "Search Title",
                            :device_id => "search_device_id",
                            :id        => "search_id")

      notif = PushHelper.open_offer(offr,srch)

      r = OneSignalHelper.
        send_message_to_player("player_id",
                               notif.localize(OpenStruct.new(:locale => "en")))
      assert_equal r["ok"], "status"
    end
  end
end
