class YouthSchoolController < ApplicationController
  before_action :signed_in_user

  def show
    set_players
    if @players.empty?
      @dates, @ai_array, @calculations = []
    else
      format_dates @players.last.ai.keys
      prepare_tables
    end
  end

  private

  def signed_in_user
    return if signed_in?
    flash[:warning] = 'You must be signed in to access that page.'
    redirect_to root_url
  end

  def set_players
    @players = YouthSchool.where(manager: params[:manager], version: params[:version],
                                 draft: params[:type] == 'draft').order('priority ASC')
  end

  def prepare_tables
    @ai_array = []
    @calculations = []
    @players.each do |player|
      player_ai = []
      ai_hash = player.ai
      ai_hash.each_key { |key| player_ai << ai_hash[key].to_i }
      @ai_array << player_ai
      calculate_calculations(player_ai)
    end
  end

  def format_dates(dates)
    @dates = []
    dates.sort.each do |key|
      time = key.to_time.getgm + 1.days
      @dates << "#{time.day}.#{time.month}"
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
