require 'json'

class App < Sinatra::Application

  def date(json_str, opts:{}) 
    obj = JSON.parse(json_str)
    obj[:server_date] = Time.now.getutc.to_f
    obj.to_json(opts)
  end

  get '/room/:id' do
    id = params[:id]
    if !request.websocket?
      haml :room, locals: {room: Room[params[:id].to_i], msgs: settings.rooms[params[:id]][0..5]}
    else
      request.websocket do |ws|
        ws.onopen { settings.sockets[id] << ws }
        ws.onmessage do |msg| 
          msg = date(msg)
          settings.rooms[id].push(msg)
          puts settings.rooms.inspect
          EM.next_tick { settings.sockets[id].each{|s| s.send(msg) } } 
        end
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

  get "/rooms" do
    rooms = Room.all
    respond_to do | wants|
      wants.json { rooms.to_json }
    end
  end
end
