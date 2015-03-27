class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5758
    @connection = ActiveRecord::Base.connection
    @distinct = @connection.exec_query('SELECT DISTINCT name FROM players WHERE age IN (19,20)')
    @players = []
    @distinct.each do |distinct|
      @players << Player.where("name = ?", distinct["name"]).limit(2).order("id DESC")
    end
  end

  def show5960
    @connection = ActiveRecord::Base.connection
    @distinct = @connection.exec_query('SELECT DISTINCT name FROM players WHERE age=18').to_a
    @distinct.delete_if do |player|
      new_player = Player.find_by name: player["name"], age: 19
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
    player = Player.find(params[:id])
    player_name = player.name
    player_age = player.age
    player.destroy
    flash[:success] = "#{player_name} (id: #{params[:id]}) deleted."
    new_player = Player.find_by name: player_name
    if new_player.nil?
      if player_age == 17
        redirect_to players5960_path
      else
        redirect_to players5758_path
      end
    else
      redirect_to player_path(new_player)
    end
  end

  def delete_all
    player = Player.find(params[:id])
    player_name = player.name
    player_age = player.age
    Player.delete_all(["name = ?", player_name])
    flash[:success] = "All instances of #{player_name} deleted."
    if player_age == 17
      redirect_to players5960_path
    else
      redirect_to players5758_path
    end
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