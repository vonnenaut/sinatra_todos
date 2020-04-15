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

# Views all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Retrieves the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Edit an existing to-do list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
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

# 
def error_for_todo(name)
  if !(1..100).cover? name.size
    "To-do must be between 1 and 100 characters."
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

# Updates an existing to-do list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list name has been updated."
    redirect "/lists/#{id}"
  end
end

# Deletes an existing to-do list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Adds a new to-do item to a to-do list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The to-do item was added."
    redirect "/lists/#{@list_id}"
  end
end

# Deletes an item from a to-do list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  todo_id = params[:id].to_i
  @list[:todos].delete_at todo_id
  session[:success] = "The to-do item has been deleted."
  redirect "/lists/#{@list_id}"
end

# Marks an item from a to-do list as completed
post "/lists/:list_id/todos/completed" do
  
  redirect "/lists/:list_id"
end