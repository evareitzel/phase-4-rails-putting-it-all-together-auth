# users#create (alt setup)
  def create
    user = User.create(user_params)
    if user.valid?
      session[:user_id] = user.id
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages },status: :unprocessable_entity
    end
  end

  #### My code before refactor - 4 tests failing:
    # GET /me
    # returns the second user when the second user is logged in

    # POST /recipes
    # with a logged in user and valid data
    #   creates a new recipe in the database
    #   returns the new recipe along with its associated user
    #   returns a 201 (Created) HTTP status code


#### My controller code:

## application_controller.rb

class ApplicationController < ActionController::API
  include ActionController::Cookies

  # before_action :authorize

  # private

  # def authorize(exception)
  #   return render json: { errors: [exception.record.errors.full_messages] }, status: :unauthorized unless session.include? :user_id 
  # end


end


## recipes_controller.rb

class RecipesController < ApplicationController
  before_action :authorize

  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response

  # GET /recipes
  def index
    render json: Recipe.all
  end

  # POST /recipes
  def create
    recipe = Recipe.create!(recipe_params) #!
    render json: recipe, status: :created
  end


  private

  def recipe_params
    params.permit(:title, :instructions, :minutes_to_complete) # :user_id, 
  end

  def authorize
    return render json: { errors: ["Not authorized"] }, status: :unauthorized unless session.include? :user_id 
  end

  def render_unprocessable_entity_response(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

end


## sessions_controller.rb

class SessionsController < ApplicationController
  before_action :authorize # move to App_controller
  skip_before_action :authorize, only: [:create]

  # POST /login
  def create
    user = User.find_by(username: params[:username]) # global var?
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      render json: user, status: :created
    else
      render json: { errors: ["Invalid username or password"] }, status: :unauthorized
    end
  end

  # DELETE /logout
  def destroy
    # current_user = User.find_by(username: params[:username])
    # if session[:user_id] # use global current_user var
    # if current_user 
    session.delete :user_id
    head :no_content
    # end
  end


  private
  
  def authorize
    return render json: { errors: ["Not authorized"] }, status: :unauthorized unless session.include? :user_id 
  end

end


## users_controller.rb

class UsersController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response

  # POST /signup
  def create
    user = User.create!(user_params)
      session[:user_id] = user.id
      render json: user, status: :created
  end

  # GET /me
  def show
      return render json: { error: "Not authorized" }, status: :unauthorized unless session.include? :user_id
      user = User.find_by(params[:id]) # make this a global var!!!! # :user_id
      render json: user, status: :created
  end


  private

  def user_params
    params.permit(:username, :password, :password_confirmation, :image_url, :bio)
  end

  def render_unprocessable_entity_response(exception)
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

end


######################################## Refactored controllers with notes

## application_controller.rb
class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authorize

  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response


  private

  # def authorize
  #   return render json: { errors: ["Not authorized"] }, status: :unauthorized unless session.include? :user_id 
  # end

  def authorize
    @current_user = User.find_by(id: session[:user_id]) #
  
    render json: { errors: ["Not authorized"] }, status: :unauthorized unless @current_user
  end  

  def render_unprocessable_entity_response(exception) # invalid
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

end


## recipes_controller.rb
class RecipesController < ApplicationController

  # GET /recipes
  def index
    render json: Recipe.all
  end

  # POST /recipes
  def create
    user = User.find_by(id: session[:user_id]) # why .find_by, not .find when arg is id - because it's complex?
    recipe = user.recipes.create!(recipe_params) # why recipes, not Recipe? why does classname not worked as a chained method? (because it's a class not a method?)
    render json: recipe, status: :created
  end


  private

  def recipe_params
    params.permit(:title, :instructions, :minutes_to_complete)
  end

end


## sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :authorize, only: :create

  # POST /login
  def create # why is custom if/else statement needed?
    user = User.find_by(username: params[:username]) # why not a global var? - nonexistent pre-login?
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      render json: user
    else
      render json: { errors: ["Invalid username or password"] }, status: :unauthorized
    end
  end

  # DELETE /logout
  def destroy
    session.delete :user_id
    head :no_content
  end
  
end


## user_controller.rb
class UsersController < ApplicationController
  skip_before_action :authorize, only: :create

  # POST /signup
  def create
    user = User.create!(user_params)
      session[:user_id] = user.id
      render json: user, status: :created
  end

  # GET /me
  def show
      # user = User.find_by(id: session[:user_id])
      render json: @current_user # user
  end


  private

  def user_params
    params.permit(:username, :password, :password_confirmation, :image_url, :bio)
  end

end


