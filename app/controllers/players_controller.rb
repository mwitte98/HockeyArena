class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5758
    @players = Player.order("id DESC").where({age: [18, 19], created_at: (Time.now - 2.day)..Time.now}).uniq
  end

  def show5960
    @players = Player.order("id DESC").where({age: [17], created_at: (Time.now - 2.day)..Time.now}).uniq
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
    UpdateJob.new.async.perform()
    redirect_to players5758_path
  end

  # def get_NT_info
  #   @players = []
  #   NTJob.new.async.perform(params[:username], params[:password])
  #   redirect_to players5556_path
  # end

  private

    def signed_in_user
      unless signed_in?
        flash[:warning] = "You must be signed in to access that page."
        redirect_to root_url
      end
    end

end