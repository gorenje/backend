require 'faye/websocket'
require 'kafka'

module Analytics
  class KafkaHelpers
    class << self
      def parse(msg)
        typestr, meta, params = msg.split(' ')

        CGI.parse(params).symbolize_keys.
          merge(CGI.parse(meta).symbolize_keys).tap do |hsh|
          hsh.merge!({ :type   => typestr.split('/').last,
                       :ip_dot => int_to_ip(hsh[:ip].first),
                       :time   => Time.at(hsh[:ts].first.to_i),
                       :params => params})
        end
      rescue
        {}
      end

      private

      def int_to_ip(i)
        begin
          return IPAddr.new(i.to_i, Socket::AF_INET).to_s
        rescue
          begin
            return IPAddr.new(i.to_i, Socket::AF_INET6).to_s
          rescue
            return "0"
          end
        end
      end
    end
  end

  class Kafidx
    def initialize(app)
      @app     = app
      @clients = []
      @thread  = nil

      topic = "#{ENV['CLOUDKARAFKA_TOPIC_PREFIX']}trk"
      @proc = Proc.new do |kafka_group_id|
        @thread = Thread.new do
          $kafka["kafidx"].
            consumer(:group_id => kafka_group_id).tap do |c|
            c.subscribe(topic)
          end.each_message(:max_wait_time => 0) do |message|
            @clients.each do |ws|
              event = {
                :topic       => topic,
                :_msgvalue_  => message.value,
                :_offset_    => message.offset,
                :_partition_ => message.partition,
                :_msgkey_    => message.key
              }.merge(Analytics::KafkaHelpers.parse(message.value))

              ws.send(event.to_json)
            end
          end
        end
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env) && env["rack.session"][:kafka_group_id]
        ws = Faye::WebSocket.new(env, nil, { :ping => 20 })

        ws.on :open do
          @clients << ws
          @proc.call(env["rack.session"][:kafka_group_id]) if @thread.nil?
        end

        ws.on :close do
          @clients.delete(ws)
          ws = nil
          ( @thread.kill ; @thread = nil ) if @clients.empty?
        end

        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
