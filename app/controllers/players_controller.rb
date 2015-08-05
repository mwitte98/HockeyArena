class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5960
    @player_instances = Player.where(team: "5960")
    @players = prepare_tables(@player_instances)
  end

  def show6162
    @player_instances = Player.where(team: "6162")
    @players = prepare_tables(@player_instances)
  end
  
  def showSenior
    @player_instances = Player.where(team: "senior")
    @players = prepare_tables(@player_instances)
  end

  def show
    @player = Player.find(params[:id])
    @dates = []
    @player.daily.keys.sort.each do |date|
      @dates << date
    end
    @dates.reverse!
  end

  def destroy
    num_instances = params[:player_ids].size
    player = Player.where(id: params[:player_ids][0]).limit(1).order("id DESC")
    player_name = player.first.name
    player_age = player.first.age
    Player.destroy_all(id: params[:player_ids])
    flash[:success] = "#{num_instances} instances of #{player_name} deleted."
    if player_age == 17 || player_age == 18
      redirect_to players6162_path
    else
      redirect_to players5960_path
    end
  end

  def delete_all
    player = Player.find(params[:id])
    player_name = player.name
    player_age = player.age
    Player.delete_all(["name = ?", player_name])
    flash[:success] = "All instances of #{player_name} deleted."
    if player_age == 17 || player_age == 18
      redirect_to players6162_path
    else
      redirect_to players5960_path
    end
  end

  def login_HA
    
  end

  def get_info
    UpdateJob.new.async.perform()
    redirect_to players5960_path
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
    
    def prepare_tables(player_instances)
      players = []
      player_instances.each do |instance|
        keys = []
        instance.daily.keys.sort.each do |key|
          keys << key
        end
        dates = keys[-2..-1]
        if dates.nil?
          dates = keys
        end
        player = []
        dates.each do |date|
          player << instance.daily[date]
        end
        players << player
      end
      return players
    end

end