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
end
