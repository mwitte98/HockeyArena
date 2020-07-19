class PlayersController < ApplicationController
  before_action :signed_in_user

  def show_national_team
    @players = []
    @player_instances = Player.where(team: params[:team])
    @player_instances.each do |instance|
      @players << get_last_two(instance.daily)
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
    player.destroy
    flash[:success] = "#{player.name} deleted."
    redirect_to national_path(team: player.team)
  end

  def update_info
    UpdateJob.perform_async
    redirect_to national_path(team: ENV['U20_20_seasons'])
  end

  private

  def signed_in_user
    return if signed_in?

    flash[:warning] = 'You must be signed in to access that page.'
    redirect_to root_url
  end

  def get_last_two(daily)
    keys = []
    daily.keys.sort.each { |key| keys << key }
    dates = keys[-2..]
    dates = keys if dates.nil?
    player = []
    dates.each { |date| player << daily[date] }
    player
  end
end
