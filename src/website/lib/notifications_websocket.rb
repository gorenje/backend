require 'faye/websocket'

module Notifications
  class Websocket
    def cdn_host
      (host = CdnHosts.sample).nil? ? "" : "//#{host}"
    end

    def initialize(app)
      @app     = app
      @clients = {}

      @proc = Proc.new do |ws, user|
        Thread.new do
          loop_count = 100
          while (loop_count-=1) > 0
            tstmp = Time.now.to_i
            nc = user.unread_notification_count
            ws.send({ :unread_count => nc,
                      :image_src => "#{cdn_host}/images/" +
                                    "notifications/#{nc}.svg?t=#{tstmp}"
                    }.to_json)
            sleep 10
          end
          ws.close
        end
      end
    end

    def call(env)
      if Faye::WebSocket.websocket?(env) && env["rack.session"][:user_id]
        ws = Faye::WebSocket.new(env, nil, { :ping => 20 })

        ws.on :open do
          @clients[ws] =
            @proc.call(ws, User.find(env["rack.session"][:user_id]))
        end

        ws.on :close do
          @clients[ws].kill
          @clients.delete(ws)
        end

        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
