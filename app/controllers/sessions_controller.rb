class SessionsController < ApplicationController
  def new; end

  def create
    session = params[:session]
    user = User.find_by(email: session[:email].downcase)
    if user&.authenticate(session[:password])
      sign_in user
      redirect_to root_url
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
