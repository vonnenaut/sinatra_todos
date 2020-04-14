require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# views all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# renders the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# renders the edit list form
get "/lists/:id/edit" do
  list_id = params[:id].to_i
  @name = session[:lists][list_id]
  erb :edit_list, layout: :layout
end

# Returns an error message if the name is invalid (wrong length or already in use); otherwise returns nil if valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name }
    "List name must be unique."
  end
end

# Creates a new list, verifying first that it's not without a name or using all space characters
post "/lists" do
  list_name = params[:list_name].strip
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Views a specific list and its tasks
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  if @list_id > session[:lists].length - 1
    session[:error] = "That To-Do list doesn't exist."
    redirect "/lists"
  else
    erb :list, layout: :layout
  end
end

