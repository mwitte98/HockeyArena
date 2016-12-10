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
      calculations << calculate_calculations(player, player_ai)
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

  def calculate_calculations(player, player_ai)
    player_calculations = []
    length = player_ai.length
    player_calculations << player_ai.inject(:+).to_f / length # average
    player_calculations << player_ai.min # min
    sorted = player_ai.sort
    player_calculations << (sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0 # median
    player_calculations << player_ai.max # max
    player_calculations << 0 # times above ai for age
    age = player.age
    player_ai.each { |ai| player_calculations[4] += 1 if above_ai_for_age?(age, ai) }
    player_calculations
  end

  def above_ai_for_age?(age, ai)
    # if age = 16, ai > 40; if age = 17, ai > 70; if age = 18, ai > 100
    ai >= 10 + (age - 15) * 30
  end
end
