class YouthSchoolController < ApplicationController
  before_action :signed_in_user

  def show
    manager = params[:manager]
    version = params[:version]
    type = params[:type]
    is_draft = type == 'draft'
    @title = "#{manager} #{version.capitalize} "
    @title += is_draft ? type.capitalize : type.upcase
    @players = YouthSchool.where(manager: manager, version: version, draft: is_draft)
                          .order('priority ASC')
    @dates, @ai_array, @calculations = prepare_tables(@players)
  end

  private

  def signed_in_user
    return if signed_in?
    flash[:warning] = 'You must be signed in to access that page.'
    redirect_to root_url
  end

  def prepare_tables(players)
    return [], [], [] if players.empty?
    dates = format_dates players.last
    ai_array = []
    calculations = []
    players.each do |player|
      player_ai = []
      ai_hash = player.ai
      ai_hash.keys.sort.each { |key| player_ai << ai_hash[key].to_i }
      ai_array << player_ai
      calculations << calculate_calculations(player_ai)
    end
    [dates, ai_array, calculations]
  end

  def format_dates(player)
    dates = []
    player.ai.keys.sort.each do |key|
      time = key.to_time.getgm + 1.days
      dates << "#{time.day}.#{time.month}"
    end
    dates
  end

  def calculate_calculations(player_ai)
    [
      player_ai.inject(:+).to_f / player_ai.length, # average
      player_ai.min, # min
      player_ai.max # max
    ]
  end
end
