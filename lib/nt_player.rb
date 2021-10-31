class NtPlayer
  attr_reader :player_attributes, :is_scouted

  def initialize(player_attributes)
    @player_attributes = player_attributes
    player_team = player_attributes[5]
    manager = State.manager
    @is_on_team = (manager == 'speedysportwhiz' && player_team == 'RIT Tigers') ||
                  (manager == 'magicspeedo' && player_team == 'McDeedo Punch')
    @is_scouted = player_attributes.size > 35
  end

  def ai
    @player_attributes[0]
  end

  def age
    @player_attributes[2]
  end

  def attributes
    hash = { goalie: 16, defense: 18, offense: 20, shooting: 22, passing: 24, speed: 17,
             strength: 19, selfcontrol: 21, experience: 25 }

    attr_hash = {}
    hash.each_key do |key|
      attr_hash[key] = return_attribute @player_attributes[hash[key]]
    end
    attr_hash
  end

  def games
    return_stat 0
  end

  def minutes
    minutes_string = return_stat 2
    minutes_string.include?('(') ? minutes_string.split[0] : minutes_string
  end

  private

  def return_attribute(value)
    return unless @is_scouted
    return value[0] if value[2] == '('
    return value[0..1] if value[3] == '('
    return value[0..2] if value[4] == '('

    value
  end

  def return_stat(offset)
    if @is_scouted && @is_on_team
      player_attributes[34 + offset]
    elsif @is_scouted
      player_attributes[31 + offset]
    else
      player_attributes[19 + offset]
    end
  end
end
