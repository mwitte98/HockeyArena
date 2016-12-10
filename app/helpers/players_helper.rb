module PlayersHelper
  def average_minutes(player)
    minutes = player['minutes']
    games = player['games']
    return 0 if minutes.zero? || games.zero?
    format '%.2f', minutes.to_f / games
  end

  def calculate_ai(player)
    goalie = player['goalie']
    return 0 if goalie.nil?
    goalie + player['defense'] + player['offense'] + player['shooting'] +
      player['passing'] + player['speed'] + player['strength'] + player['selfcontrol']
  end
end
