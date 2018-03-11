class Worksheet
  attr_reader :team, :ws
  attr_writer :manager

  def initialize(params = {})
    @ws = params[:ws]
    @team = params[:team]
    @is_senior_team = @team == 'senior'
  end

  def update_row?(row_num)
    @row = row_num
    if @manager == 'speedysportwhiz'
      update_row_for_speedy?
    else
      update_row_for_speedo?
    end
  end

  def mark_player_as_deleted
    (2..27).each { |column| ws[@row, column] = 'DELETE' }
  end

  def update_row(player)
    update_stats player
    return unless player.is_scouted
    update_primary_attrs player
    update_secondary_attrs player
  end

  def player_hash
    stats_hash.merge(primary_attrs_hash).merge(secondary_attrs_hash)
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
    is_y = ws[@row, 30] == 'y'
    (!@is_senior_team && !is_y) || (@is_senior_team && is_y)
  end

  def update_row_for_speedo?
    is_y = ws[@row, 30] == 'y'
    (!@is_senior_team && is_y) || (@is_senior_team && !is_y)
  end

  def update_stats(player)
    @ws[@row, 2] = player.age if @is_senior_team
    @ws[@row, 3] = player.ai
    @ws[@row, 22] = player.games
    @ws[@row, 23] = player.minutes
  end

  def update_primary_attrs(player)
    @ws[@row, 8] = player.goalie
    @ws[@row, 9] = player.defense
    @ws[@row, 10] = player.offense
    @ws[@row, 11] = player.shooting
  end

  def update_secondary_attrs(player)
    @ws[@row, 12] = player.passing
    @ws[@row, 13] = player.speed
    @ws[@row, 14] = player.strength
    @ws[@row, 15] = player.selfcontrol
    @ws[@row, 17] = player.experience
  end

  def stats_hash
    {
      ai: @ws[@row, 3].to_i,
      stadium: @ws[@row, 6].to_i,
      playertype: @ws[@row, 16],
      games: @ws[@row, 22].to_i,
      minutes: @ws[@row, 23].to_i
    }
  end

  def primary_attrs_hash
    {
      goalie: @ws[@row, 8].to_i,
      defense: @ws[@row, 9].to_i,
      offense: @ws[@row, 10].to_i,
      shooting: @ws[@row, 11].to_i
    }
  end

  def secondary_attrs_hash
    {
      passing: @ws[@row, 12].to_i,
      speed: @ws[@row, 13].to_i,
      strength: @ws[@row, 14].to_i,
      selfcontrol: @ws[@row, 15].to_i,
      experience: @ws[@row, 17].to_i
    }
  end
end
