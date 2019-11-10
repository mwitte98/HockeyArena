module PlayersHelper
  def average_minutes(player)
    minutes = player[12]
    games = player[11]
    return 0 if minutes.zero? || games.zero?

    format '%.2f', minutes.to_f / games
  end

  def calculate_ai(player)
    total = 0
    (2..9).each do |attribute|
      value = player[attribute]
      total += value unless value.nil?
    end
    total
  end
end
