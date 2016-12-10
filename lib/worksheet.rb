class Worksheet
  attr_reader :team, :ws
  attr_writer :manager

  def initialize(params = {})
    @ws = params[:ws]
    @team = params[:team]
    @is_senior_team = @team == 'senior'
    @col = @is_senior_team ? 1 : 0
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
    self.age = player.age if @is_senior_team
    self.ai = player.ai
    self.games = player.games
    self.minutes = player.minutes

    # update attributes if player is scouted
    return unless player.player_attributes.size > 35
    self.goalie = player.goalie
    self.defense = player.defense
    self.offense = player.offense
    self.shooting = player.shooting
    self.passing = player.passing
    self.speed = player.speed
    self.strength = player.strength
    self.selfcontrol = player.selfcontrol
    self.experience = player.experience
  end

  def player_hash
    {
      ai: ai.to_i,
      stadium: stadium.to_i,
      goalie: goalie.to_i,
      defense: defense.to_i,
      offense: offense.to_i,
      shooting: shooting.to_i,
      passing: passing.to_i,
      speed: speed.to_i,
      strength: strength.to_i,
      selfcontrol: selfcontrol.to_i,
      playertype: playertype,
      experience: experience.to_i,
      games: games.to_i,
      minutes: minutes.to_i
    }
  end

  def name
    @ws[@row, 1]
  end

  def age
    @ws[@row, 2]
  end

  def quality
    @ws[@row, 3 + @col]
  end

  def potential
    @ws[@row, 4 + @col]
  end

  def stadium=(value)
    @ws[@row, 5 + @col] = value
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

  def age=(value)
    @ws[@row, 2] = value
  end

  def ai
    @ws[@row, 2 + @col]
  end

  def ai=(value)
    @ws[@row, 2 + @col] = value
  end

  def stadium
    @ws[@row, 5 + @col]
  end

  def goalie
    @ws[@row, 7 + @col]
  end

  def goalie=(value)
    @ws[@row, 7 + @col] = value
  end

  def defense
    @ws[@row, 8 + @col]
  end

  def defense=(value)
    @ws[@row, 8 + @col] = value
  end

  def offense
    @ws[@row, 9 + @col]
  end

  def offense=(value)
    @ws[@row, 9 + @col] = value
  end

  def shooting
    @ws[@row, 10 + @col]
  end

  def shooting=(value)
    @ws[@row, 10 + @col] = value
  end

  def passing
    @ws[@row, 11 + @col]
  end

  def passing=(value)
    @ws[@row, 11 + @col] = value
  end

  def speed
    @ws[@row, 12 + @col]
  end

  def speed=(value)
    @ws[@row, 12 + @col] = value
  end

  def strength
    @ws[@row, 13 + @col]
  end

  def strength=(value)
    @ws[@row, 13 + @col] = value
  end

  def selfcontrol
    @ws[@row, 14 + @col]
  end

  def selfcontrol=(value)
    @ws[@row, 14 + @col] = value
  end

  def playertype
    @ws[@row, 15 + @col]
  end

  def experience
    @ws[@row, 16 + @col]
  end

  def experience=(value)
    @ws[@row, 16 + @col] = value
  end

  def games
    @ws[@row, 21 + @col]
  end

  def games=(value)
    @ws[@row, 21 + @col] = value
  end

  def minutes
    @ws[@row, 22 + @col]
  end

  def minutes=(value)
    @ws[@row, 22 + @col] = value
  end
end
