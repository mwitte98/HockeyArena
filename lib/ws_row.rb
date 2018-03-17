module WsRow
  def self.mark_player_as_deleted
    (2..27).each { |column| WsState.sheet[WsState.row, column] = 'DELETE' }
  end

  def self.update_row(player)
    @sheet = WsState.sheet
    @row = WsState.row
    update_stats player
    return unless player.is_scouted
    hash = { goalie: 8, defense: 9, offense: 10, shooting: 11, passing: 12, speed: 13, strength: 14,
             selfcontrol: 15, experience: 17 }
    update_attrs player, hash
  end

  def self.player_hash
    @sheet = WsState.sheet
    @row = WsState.row
    hash = {
      ai: 3, stadium: 6, goalie: 8, defense: 9, offense: 10, shooting: 11, passing: 12, speed: 13,
      strength: 14, selfcontrol: 15, playertype: 16, experience: 17, games: 22, minutes: 23
    }

    generate_player_hash hash
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
    @sheet[@row, 2] = player.age
    @sheet[@row, 3] = player.ai
    @sheet[@row, 22] = player.games
    @sheet[@row, 23] = player.minutes
  end

  private_class_method def self.update_attrs(player, hash)
    attributes = player.attributes
    hash.each_key do |key|
      @sheet[@row, hash[key]] = attributes[key]
    end
  end

  private_class_method def self.generate_player_hash(hash)
    generated_hash = {}
    hash.each_key do |key|
      value = @sheet[@row, hash[key]]
      generated_hash[key] = key == :playertype ? value : value.to_i
    end
    generated_hash
  end
end