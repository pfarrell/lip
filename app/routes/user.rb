class App < Sinatra::Application
  get "/user/new" do
    haml :user, locals: {user: User.new}
  end
end
