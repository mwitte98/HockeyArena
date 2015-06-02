class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5960
    @connection = ActiveRecord::Base.connection
    @distinct = @connection.exec_query('SELECT DISTINCT name FROM players WHERE age=19').to_a
    @distinct.delete_if do |player|
      new_player = Player.find_by name: player["name"], age: 20
      new_player.nil? ? false : true
    end
    @players = []
    @distinct.each do |distinct|
      @players << Player.where("name = ?", distinct["name"]).limit(2).order("id DESC")
    end
  end

  def show6162
    @connection = ActiveRecord::Base.connection
    @distinct = @connection.exec_query('SELECT DISTINCT name FROM players WHERE age=17').to_a
    @distinct.delete_if do |player|
      new_player = Player.find_by name: player["name"], age: 18
      new_player.nil? ? false : true
    end
    @players = []
    @distinct.each do |distinct|
      @players << Player.where("name = ?", distinct["name"]).limit(2).order("id DESC")
    end
  end

  def show
    @player = Player.find(params[:id])
    @players = Player.order("id DESC").where("name = ?", @player.name)
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

end