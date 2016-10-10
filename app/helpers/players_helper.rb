module PlayersHelper
  def average_minutes(player)
    return 0 if player['minutes'].zero? || player['games'].zero?
    format '%.2f', player['minutes'].to_f / player['games']
  end

  def calculate_ai(player)
    return 0 if player['goalie'].nil?
    player['goalie'] + player['defense'] + player['offense'] + player['shooting'] +
      player['passing'] + player['speed'] + player['strength'] + player['selfcontrol']
  end
end
