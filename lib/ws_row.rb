module WsRow
  def self.mark_player_as_deleted
    (2..27).each { |column| WsState.sheet[WsState.row, column] = 'DELETE' }
  end

  def self.update_row(player)
    @sheet = WsState.sheet
    @row = WsState.row
    update_stats player
    return unless player.is_scouted
    update_primary_attrs player
    update_secondary_attrs player
  end

  def self.player_hash
    @sheet = WsState.sheet
    @row = WsState.row
    stats_hash.merge(primary_attrs_hash).merge(secondary_attrs_hash)
  end

  def self.name
    WsState.sheet[WsState.row, 1]
  end

  def self.age
    WsState.sheet[WsState.row, 2]
  end

  def self.quality
    WsState.sheet[WsState.row, 4]
  end

  def self.potential
    WsState.sheet[WsState.row, 5]
  end

  def self.stadium=(value)
    WsState.sheet[WsState.row, 6] = value
  end

  def self.id
    WsState.sheet[WsState.row, 28]
  end

  private_class_method def self.update_stats(player)
    @sheet[@row, 2] = player.age if WsState.team == 'senior'
    @sheet[@row, 3] = player.ai
    @sheet[@row, 22] = player.games
    @sheet[@row, 23] = player.minutes
  end

  private_class_method def self.update_primary_attrs(player)
    @sheet[@row, 8] = player.goalie
    @sheet[@row, 9] = player.defense
    @sheet[@row, 10] = player.offense
    @sheet[@row, 11] = player.shooting
  end

  private_class_method def self.update_secondary_attrs(player)
    @sheet[@row, 12] = player.passing
    @sheet[@row, 13] = player.speed
    @sheet[@row, 14] = player.strength
    @sheet[@row, 15] = player.selfcontrol
    @sheet[@row, 17] = player.experience
  end

  private_class_method def self.stats_hash
    {
      ai: @sheet[@row, 3].to_i,
      stadium: @sheet[@row, 6].to_i,
      playertype: @sheet[@row, 16],
      games: @sheet[@row, 22].to_i,
      minutes: @sheet[@row, 23].to_i
    }
  end

  private_class_method def self.primary_attrs_hash
    {
      goalie: @sheet[@row, 8].to_i,
      defense: @sheet[@row, 9].to_i,
      offense: @sheet[@row, 10].to_i,
      shooting: @sheet[@row, 11].to_i
    }
  end

  private_class_method def self.secondary_attrs_hash
    {
      passing: @sheet[@row, 12].to_i,
      speed: @sheet[@row, 13].to_i,
      strength: @sheet[@row, 14].to_i,
      selfcontrol: @sheet[@row, 15].to_i,
      experience: @sheet[@row, 17].to_i
    }
  end
end
