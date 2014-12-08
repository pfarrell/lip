class App < Sinatra::Application
  get '/room/:id' do
    id = params[:id]
    if !request.websocket?
      haml :room, locals: {room: Room[params[:id].to_i]}
    else
      request.websocket do |ws|
        ws.onopen { settings.sockets[id] << ws }
        ws.onmessage { |msg| EM.next_tick { puts msg; settings.sockets[id].each{|s| s.send(msg) } } }
        ws.onclose { settings.sockets[id].delete(ws) }
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
