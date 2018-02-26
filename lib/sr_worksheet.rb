class SrWorksheet
  attr_reader :ws
  attr_writer :manager

  def initialize(params = {})
    @ws = params[:ws]
  end

  def update_row?(row_num)
    @row = row_num
    other_manager = ws[@row, 30]
    if @manager == 'speedysportwhiz'
      other_manager == 'y'
    else
      other_manager != 'y'
    end
  end

  def mark_player_as_deleted
    (2..27).each { |column| ws[@row, column] = 'DELETE' }
  end

  def update_row(player)
    @ws[@row, 2] = player.age
    @ws[@row, 3] = player.ai
    @ws[@row, 22] = player.games
    @ws[@row, 23] = player.minutes

    # update attributes if player is scouted
    return unless player.player_attributes.size > 35
    @ws[@row, 8] = player.goalie
    @ws[@row, 9] = player.defense
    @ws[@row, 10] = player.offense
    @ws[@row, 11] = player.shooting
    @ws[@row, 12] = player.passing
    @ws[@row, 13] = player.speed
    @ws[@row, 14] = player.strength
    @ws[@row, 15] = player.selfcontrol
    @ws[@row, 17] = player.experience
  end

  def player_hash
    {
      ai: @ws[@row, 3].to_i,
      stadium: @ws[@row, 6].to_i,
      goalie: @ws[@row, 8].to_i,
      defense: @ws[@row, 9].to_i,
      offense: @ws[@row, 10].to_i,
      shooting: @ws[@row, 11].to_i,
      passing: @ws[@row, 12].to_i,
      speed: @ws[@row, 13].to_i,
      strength: @ws[@row, 14].to_i,
      selfcontrol: @ws[@row, 15].to_i,
      playertype: @ws[@row, 16],
      experience: @ws[@row, 17].to_i,
      games: @ws[@row, 22].to_i,
      minutes: @ws[@row, 23].to_i
    }
  end

  def name
    @ws[@row, 1]
  end

  def age
    @ws[@row, 2]
  end

  def quality
    @ws[@row, 4]
  end

  def potential
    @ws[@row, 5]
  end

  def stadium=(value)
    @ws[@row, 6] = value
  end

  def id
    @ws[@row, 28]
  end

  private

  def update_row_for_speedy?
    is_y = ws[@row, 29] == 'y'
    (!@is_senior_team && !is_y) || (@is_senior_team && is_y)
  end

  def update_row_for_speedo?
    is_y = ws[@row, 29] == 'y'
    (!@is_senior_team && is_y) || (@is_senior_team && !is_y)
  end
end
