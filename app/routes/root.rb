class App < Sinatra::Application
  get '/' do
    haml :index, locals: {rooms: Room.all}
  end
end
