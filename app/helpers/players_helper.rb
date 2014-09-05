module PlayersHelper
  
  def average_minutes(player)
  	if player.minutes == 0 || player.games == 0
  	  return 0
  	else
  	  return sprintf "%.2f", player.minutes.to_f/player.games
  	end
  end

  def calculate_ai(player)
    if player.goalie.nil?
      return 0
    else
  	  return player.goalie + player.defense + player.offense + player.shooting + player.passing + player.speed + player.strength + player.selfcontrol
    end
  end
end
