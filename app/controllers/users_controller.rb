class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def show
    @user = User.find_by(id: params[:id])
    render_404 unless @user
  end

  def create
    auth_hash = request.env["omniauth.auth"]

    user = User.find_by(uid: auth_hash[:uid], provider: "github")

    if user
      flash[:status] = :success
      flash[:result_text] = "Successfully logged in as existing user #{user.username}"
    else
      user = User.build_from_github(auth_hash)

      if user.save
        flash[:status] = :success
        flash[:result_text] = "Successfully created new user #{user.username} with ID #{user.uid}"
      else
        flash.now[:status] = :failure
        flash.now[:result_text] = "Could not log in"
        flash.now[:messages] = user.errors.messages
        render "login_form", status: :bad_request
        return
      end

    end

    session[:user_id] = user.id
    redirect_to root_path
  end

  def logout

    if(session[:user_id].nil?)
      flash[:status] = :failure
      flash[:result_text] = "You were not logged in!"
    else
      session[:user_id] = nil
      flash[:status] = :success
      flash[:result_text] = "Successfully logged out!"
    end


    redirect_to root_path
  end

end
