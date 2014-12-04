class App < Sinatra::Application
  get "/" do
    if !request.websocket?
      haml :index
    else
      request.websocket do |ws|
        ws.onopen do
          ws.send("hello world")
          settings.sockets << ws
        end
        ws.onmessage do |msg|
          EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
        end
        ws.onclose do
          warn("websocket closed")
          settings.sockets.delete(ws)
        end
      end
    end
  end
end
