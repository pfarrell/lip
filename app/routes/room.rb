class App < Sinatra::Application
  get "/room.:id" do
    if !request.websocket?
      haml :room, locals: {room: Room[params[:room].to_i]}
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

  post "/room/new" do
    room = Room.new
    room.name = params[:name]
    room.save
    redirect(url_for("/room/#{room.id}"))
  end
end
