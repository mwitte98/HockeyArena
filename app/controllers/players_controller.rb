class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5556
    @players = Player.order("id DESC").all(conditions: ["age = ?", 19]).uniq
  end

  def show5758
    @players = Player.order("id DESC").all(conditions: ["age = ?", 17]).uniq
  end

  def show
    @player = Player.find(params[:id])
    @players = Player.order("id DESC").all(conditions: ["name = ?", @player.name])
  end

  def destroy
    Player.find(params[:id]).destroy
    flash[:success] = "Player deleted."
    redirect_to :back
  end

  def login_HA
    
  end

  def get_info
    U20Job.new.async.perform()
    redirect_to players5556_path
  end

  def get_U20_info
    NewU20Job.new.async.perform()
    redirect_to players5556_path
  end

  def get_NT_info
    @players = []
    NTJob.new.async.perform(params[:username], params[:password])
    redirect_to players5556_path
  end

  private

    def signed_in_user
      unless signed_in?
        flash[:warning] = "You must be signed in to access that page."
        redirect_to root_url
      end
    end

end