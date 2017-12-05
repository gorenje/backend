# -*- coding: utf-8 -*-
require_relative '../test_helper'
require_relative '../chatbot_test_helper'

class ChatbotTest < Minitest::Test
  def mechanize_object(url)
    Object.new.tap do |o|
      mock(o).get(url) do
        Object.new.tap do |srch|
          mock(srch).search("div#kino_accordeon > div") do
            []
          end
        end
      end
    end
  end

  context "event object" do
    should "ensure event knows it's for kino" do
      event = ChatbotTestHelper.create_event("unknonw messge")
      assert event.is_for?(Consumers::Chatbot::BerlinDeKinos)
    end
  end

  context "handle_event" do
    should "not know everything" do
      event = ChatbotTestHelper.create_event("unknonw messge")

      mock(event).offer_and_search do
        [ChatbotTestHelper::TestOffer, nil]
      end
      mock(event).post_message("Unknown", Consumers::Chatbot::BerlinDeKinos)

      consumer = Consumers::Chatbot.new
      consumer.send(:handle_event, event)
    end

    should "know when the movie is starting" do
      event = ChatbotTestHelper.create_event("when")

      mock(event).offer_and_search do
        [ChatbotTestHelper::TestOffer, nil]
      end
      mock(event).post_message("Starting at 28.08.17 20:00",
                               Consumers::Chatbot::BerlinDeKinos)

      consumer = Consumers::Chatbot.new
      consumer.send(:handle_event, event)
    end

    should "know when the movie is described" do
      event = ChatbotTestHelper.create_event("desc")

      mock(event).offer_and_search do
        [ChatbotTestHelper::TestOffer, nil]
      end
      mock(event).post_message("Check out https://www.berlin.de/kino/"+
                               "_bin/filmdetail.php/244492",
                               Consumers::Chatbot::BerlinDeKinos)

      consumer = Consumers::Chatbot.new
      consumer.send(:handle_event, event)
    end

    should "retrieve page details" do
      event = ChatbotTestHelper.create_event("wherelse")

      mock(event).offer_and_search do
        [ChatbotTestHelper::TestOffer, nil]
      end

      mock(event).
        post_message("Not screening anywhere else",
                     Consumers::Chatbot::BerlinDeKinos)

      consumer = Consumers::Chatbot.new
      mock(consumer).mechanize_agent do
        mechanize_object("https://www.berlin.de/kino/_bin/"+
                         "filmdetail.php/244492")
      end

      consumer.send(:handle_event, event)
    end

    ### This does a live retrieval, that's why it's no longer active.
    # should "retrieve page details (live)" do
    #   event = ChatbotTestHelper.create_event("wherelse")

    #   mock(event).offer_and_search do
    #     [ChatbotTestHelper::TestOffer, nil]
    #   end

    #   mock(event).
    #     post_message("Not screening anywhere else",
    #                  Consumers::Chatbot::BerlinDeKinos)

    #   consumer = Consumers::Chatbot.new

    #   consumer.send(:handle_event, event)
    # end
  end
end
