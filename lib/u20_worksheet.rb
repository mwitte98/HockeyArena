class U20Worksheet
  attr_reader :ws
  attr_writer :manager

  def initialize(params = {})
    @ws = params[:ws]
  end

  def update_row?(row_num)
    @row = row_num
    other_manager = ws[@row, 29]
    if @manager == 'speedysportwhiz'
      other_manager != 'y'
    else
      other_manager == 'y'
    end
  end

  def mark_player_as_deleted
    (2..27).each { |column| ws[@row, column] = 'DELETE' }
  end

  def update_row(player)
    @ws[@row, 2] = player.ai
    @ws[@row, 21] = player.games
    @ws[@row, 22] = player.minutes

    # update attributes if player is scouted
    return unless player.player_attributes.size > 35
    @ws[@row, 7] = player.goalie
    @ws[@row, 8] = player.defense
    @ws[@row, 9] = player.offense
    @ws[@row, 10] = player.shooting
    @ws[@row, 11] = player.passing
    @ws[@row, 12] = player.speed
    @ws[@row, 13] = player.strength
    @ws[@row, 14] = player.selfcontrol
    @ws[@row, 16] = player.experience
  end

  def player_hash
    {
      ai: @ws[@row, 2].to_i,
      stadium: @ws[@row, 5].to_i,
      goalie: @ws[@row, 7].to_i,
      defense: @ws[@row, 8].to_i,
      offense: @ws[@row, 9].to_i,
      shooting: @ws[@row, 10].to_i,
      passing: @ws[@row, 11].to_i,
      speed: @ws[@row, 12].to_i,
      strength: @ws[@row, 13].to_i,
      selfcontrol: @ws[@row, 14].to_i,
      playertype: @ws[@row, 15],
      experience: @ws[@row, 16].to_i,
      games: @ws[@row, 21].to_i,
      minutes: @ws[@row, 22].to_i
    }
  end

  def name
    @ws[@row, 1]
  end

  def age
    @ws[@row, 2]
  end

  def quality
    @ws[@row, 3]
  end

  def potential
    @ws[@row, 4]
  end

  def stadium=(value)
    @ws[@row, 5] = value
  end

  def id
    @ws[@row, 28]
  end
end
