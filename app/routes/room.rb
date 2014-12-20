require 'json'

class App < Sinatra::Application

  def meta(json_str, opts:{}) 
    obj = JSON.parse(json_str)
    obj[:server_date] = Time.now.getutc.to_f
    obj['msg'] = expand(obj['msg'])
    obj.to_json(opts)
  end

  def expand(msg) 
    msg.gsub!(/(http.*\.jp[e]?g)/, "<div><img src='\\1' /></div>")
    msg.gsub!(/(http.*\.png)/, "<div><img src='\\1' /></div>")
    msg.gsub!(/(http.*\.gif)/, "<div><img src='\\1' /></div>")
    msg.gsub!(/http.*youtube.com\/watch\?v=([A-Za-z0-9\-_#=?]*)/, "<div><iframe width='560' height='315' src='//www.youtube.com/embed/\\1' frameborder='0' allowfullscreen></iframe></div>")
    puts msg
    msg
  end

  get '/room/:id' do
    id = params[:id]
    if !request.websocket?
      len = settings.redis.llen(id)
      msgs = settings.redis.lrange(id,-5,len)
      msgs=[] if msgs == ""
      haml :room, locals: {room: Room[id.to_i], msgs: msgs, user: cookies[:user]}
    else
      request.websocket do |ws|
        ws.onopen { settings.sockets[id] << ws }
        ws.onmessage do |msg| 
          msg = meta(msg)
          settings.redis.rpush(id, msg)
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
