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
    sheet = WsState.sheet
    row = WsState.row
    hash = {
      ai: 3, stadium: 6, goalie: 8, defense: 9, offense: 10, shooting: 11, passing: 12, speed: 13,
      strength: 14, selfcontrol: 15, playertype: 16, experience: 17, games: 22, minutes: 23
    }

    generated_hash = {}
    hash.each_key do |key|
      value = sheet[row, hash[key]]
      generated_hash[key] = key == :playertype ? value : value.to_i
    end
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
end
