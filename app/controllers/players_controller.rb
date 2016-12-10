class PlayersController < ApplicationController
  before_action :signed_in_user

  def show_national_team
    params_team = params[:team]
    team = if params_team == 'u20_active'
             ENV['U20_20_seasons']
           elsif params_team == 'u20_next'
             ENV['U20_18_seasons']
           else
             'senior'
           end
    @players = []
    @player_instances = Player.where(team: team)
    @player_instances.each do |instance|
      daily = instance.daily
      keys = []
      daily.keys.sort.each { |key| keys << key }
      dates = keys[-2..-1]
      dates = keys if dates.nil?
      player = []
      dates.each { |date| player << daily[date] }
      @players << player
    end
  end

  def show
    @player = Player.find(params[:id])
    @dates = []
    @player.daily.keys.sort.each do |date|
      @dates << date
    end
    @dates.reverse!
  end

  def delete_all
    player = Player.find(params[:id])
    player_name = player.name
    player_team = player.team
    Player.delete_all(['name = ?', player_name])
    flash[:success] = "#{player_name} deleted."
    if player_team == ENV['U20_20_seasons']
      redirect_to national_path(team: 'u20_active')
    elsif player_team == ENV['U20_18_seasons']
      redirect_to national_path(team: 'u20_next')
    else
      redirect_to national_path(team: 'senior')
    end
  end

  def update_info
    UpdateJob.new.async.perform
    redirect_to national_path(team: 'u20_active')
  end

  private

  def signed_in_user
    return if signed_in?
    flash[:warning] = 'You must be signed in to access that page.'
    redirect_to root_url
  end
end
