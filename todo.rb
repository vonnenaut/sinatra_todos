require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def load_list(id)
    list = session[:lists].find{ |list| list[:id] == id }
    return list if list

    session[:error] = "The specified list was not found."
    redirect "/lists"
  end

  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end

  def next_element_id(elements)
    max = elements.map { |element| element[:id] }.max || 0
    max + 1
  end
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
    id = next_element_id(session[:lists])
    session[:lists] << {id: id, name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Views a specific list and its tasks
get "/lists/:id" do
  id = params[:id].to_i
  list = load_list(id)
  @list_name = list[:name]
  @list_id = list[:id]
  @todos = list[:todos]

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
  # Ajax request
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    # request made by standard form submission
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# Adds a new to-do item to a to-do list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << {id: id, name: text, completed: false}
    session[:success] = "The to-do item was added."
    redirect "/lists/#{@list_id}"
  end
end

# Deletes an item from a to-do list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    # ajax request
    status 204
  else
    # request made by standard form submission
    session[:success] = "The to-do item has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Marks an item from a to-do list as completed
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  item_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  item = @list[:todos].find { |item| item[:id] == item_id }
  item[:completed] = is_completed

  session[:success] = "The to-do item has been marked as complete."
  redirect "/lists/#{@list_id}"
end

# Mark all items from a to-do list as completed
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All to-do items have been marked as complete."
  redirect "/lists/#{@list_id}"
end
