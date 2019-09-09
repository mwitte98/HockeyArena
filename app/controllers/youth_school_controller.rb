class YouthSchoolController < ApplicationController
  before_action :signed_in_user

  def show
    @players = players.sort_by { |player| player.ai.length }
    @dates = []
    @ai_array = []
    @calculations = []
    format_dates @players.last&.ai&.keys || []
    prepare_tables
  end

  private

  def signed_in_user
    return if signed_in?

    flash[:warning] = 'You must be signed in to access that page.'
    redirect_to root_url
  end

  def players
    YouthSchool.where(
      manager: params[:manager], version: params[:version], draft: params[:type] == 'draft',
      team: params[:team]
    )
  end

  def format_dates(dates)
    dates.sort.each do |key|
      time = key.to_time.getgm + 1.days
      @dates << "#{time.day}.#{time.month}"
    end
  end

  def prepare_tables
    @players.each do |player|
      player_ai = player.ai.map { |_key, value| value.to_i }
      @ai_array << player_ai
      calculate_calculations(player_ai)
    end
  end

  def calculate_calculations(player_ai)
    @calculations << [
      player_ai.inject(:+).to_f / player_ai.length, # average
      player_ai.min, # min
      player_ai.max # max
    ]
  end
end
