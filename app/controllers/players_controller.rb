class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5354
    #@players = Player.order("ai DESC").all(:conditions => ["age != ?", 17])
    @players = []
  end

  def show5556
    #@players = Player.order("ai DESC").all(:conditions => ["age = ?", 17])
    @players = []
  end

  def login_HA
    
  end

  def get_info
    U20Job.new.async.perform()
    flash[:success] = "U20 players are being updated!"
    redirect_to players5354_path
  end

  def get_NT_info
    NTJob.new.async.perform()
    flash[:success] = "NT players are being updated!"
    redirect_to players5354_path
  end

  private

    def signed_in_user
      unless signed_in?
        flash[:warning] = "You must be signed in to access that page."
        redirect_to root_url
      end
    end

end