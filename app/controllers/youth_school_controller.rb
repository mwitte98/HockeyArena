class YouthSchoolController < ApplicationController
  before_action :signed_in_user, only: :show

  def show
    @players = players.sort_by { |player| player.ai.length }
    @dates = []
    @ai_array = []
    @calculations = []
    format_dates @players.last&.ai&.keys || []
    prepare_tables
  end

  def update
    UpdateJob.perform_async
  end

  private

  def signed_in_user
    return if signed_in?

    flash[:warning] = 'You must be signed in to access that page.'
    redirect_to root_url
  end

  def players
    YouthSchool.where(
      version: params[:version], draft: params[:type] == 'draft', team: params[:team], :updated_at.gte => 1.day.ago
    )
  end

  def format_dates(dates)
    dates.sort.each do |key|
      time = Time.zone.parse(key)
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
