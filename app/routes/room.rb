require 'json'

class App < Sinatra::Application

  def meta(json_str, opts:{}) 
    obj = JSON.parse(json_str)
    obj[:server_date] = Time.now.getutc.to_f
    obj['msg'] = expand(obj['msg'])
    obj.to_json(opts)
  end

  def expand(msg) 
    msg.gsub!(/(http.*\.jp[e]?g)/, "<img src='\\1' />")
    msg.gsub!(/(http.*\.png)/, "<img src='\\1' />")
    msg.gsub!(/(http.*\.gif)/, "<img src='\\1' />")
    msg.gsub!(/http.*youtube.com\/watch\?v=([A-Za-z0-9-_]*)/, "<iframe width='560' height='315' src='//www.youtube.com/embed/\\1' frameborder='0' allowfullscreen></iframe>")
    puts msg
    msg
  end

  get '/room/:id' do
    id = params[:id]
    if !request.websocket?
      haml :room, locals: {room: Room[params[:id].to_i], msgs: settings.rooms[params[:id]][0..5], user: cookies[:user]}
    else
      request.websocket do |ws|
        ws.onopen { settings.sockets[id] << ws }
        ws.onmessage do |msg| 
          msg = meta(msg)
          settings.rooms[id].push(msg)
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
