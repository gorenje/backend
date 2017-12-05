require_relative 'event'

module Consumers
  module Kafka
    class ChatbotEvent < Consumers::Kafka::Event
      def initialize(payload)
        super(payload)
      end

      def members
        params[:mbers]
      end

      def channel_url
        params[:churl].try(:first)
      end

      def subject_ids
        params[:chnam].try(:first).try(:split, /_/)
      end

      def sender
        params[:snder].try(:first)
      end

      def message_text
        params[:msg].try(:first)
      end

      def is_for?(user)
        (members || []).include?(user) && sender != user
      end

      def offer_and_search
        query_str = {"_id" => params[:chnam].first}.to_query
        data      = StoreHelper::Agent.new.chat.byids.get(query_str)
        [ data["offers"].first, data["searches"].first ]
      end

      def post_message(msg, user)
        data = {
          "message_type" => "MESG",
          "user_id"      => user,
          "message"      => msg
        }

        SendbirdApi.new.group_channels.send(channel_url).messages.post(data)
      end
    end
  end
end
