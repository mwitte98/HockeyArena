module PlayersHelper
  def average_minutes(player)
    minutes = player['minutes']
    games = player['games']
    return 0 if minutes.zero? || games.zero?
    format '%.2f', minutes.to_f / games
  end

  def calculate_ai(player)
    total = 0
    attributes = %w[goalie defense offense shooting passing speed strength selfcontrol]
    attributes.each do |attribute|
      value = player[attribute]
      total += value unless value.nil?
    end
    total
  end
end
