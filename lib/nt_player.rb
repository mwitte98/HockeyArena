class NtPlayer
  attr_reader :player_attributes
  attr_reader :is_scouted

  def initialize(player_attributes)
    @player_attributes = player_attributes
    mgr = player_attributes[3]
    player_team = player_attributes[5]
    @is_on_team = (mgr == 'speedysportwhiz' && player_team == 'RIT Tigers') ||
                  (mgr == 'magicspeedo' && player_team == 'McDeedo Punch')
    @is_scouted = player_attributes.size > 35
  end

  def ai
    @player_attributes[0]
  end

  def age
    @player_attributes[2]
  end

  def goalie
    return_attribute @player_attributes[16]
  end

  def defense
    return_attribute @player_attributes[18]
  end

  def offense
    return_attribute @player_attributes[20]
  end

  def shooting
    return_attribute @player_attributes[22]
  end

  def passing
    return_attribute @player_attributes[24]
  end

  def speed
    return_attribute @player_attributes[17]
  end

  def strength
    return_attribute @player_attributes[19]
  end

  def selfcontrol
    return_attribute @player_attributes[21]
  end

  def experience
    return_attribute @player_attributes[25]
  end

  def games
    return_stat 0
  end

  def minutes
    return_stat 2
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
    elsif @is_scouted && !@is_on_team
      player_attributes[31 + offset]
    else
      player_attributes[19 + offset]
    end
  end
end
