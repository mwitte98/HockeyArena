class CombineEachPlayer < ActiveRecord::Migration
  def change
    add_column :players, :team, :string
    add_column :players, :daily, :json

    # get most recent instance of each player
    @connection = ActiveRecord::Base.connection
    @distinct = @connection.exec_query('SELECT DISTINCT name FROM players WHERE age=19').to_a
    @distinct.delete_if do |player|
      new_player = Player.find_by name: player['name'], age: 20
      new_player.nil? ? false : true
    end
    @players = []
    @distinct.each do |distinct|
      @players << Player.where(name: distinct['name']).limit(1).order('id DESC').first
    end
    @distinct = @connection.exec_query('SELECT DISTINCT name FROM players WHERE age=17').to_a
    @distinct.delete_if do |player|
      new_player = Player.find_by name: player['name'], age: 18
      new_player.nil? ? false : true
    end
    @distinct.each do |distinct|
      @players << Player.where(name: distinct['name']).limit(1).order('id DESC').first
    end

    # create new instance of each player and delete all old instances
    @players.each do |player|
      playerid = player.playerid
      name = player.name
      age = player.age
      quality = player.quality
      potential = player.potential
      if age == 19
        team = '5960'
      elsif age == 17
        team = '6162'
      end
      daily = {}
      instances = Player.where(name: name).order('id ASC')
      instances.each do |instance|
        day = {}
        day['ai'] = instance.ai
        day['stadium'] = instance.stadium
        day['goalie'] = instance.goalie
        day['defense'] = instance.defense
        day['offense'] = instance.offense
        day['shooting'] = instance.shooting
        day['passing'] = instance.passing
        day['speed'] = instance.speed
        day['strength'] = instance.strength
        day['selfcontrol'] = instance.selfcontrol
        day['playertype'] = instance.playertype
        day['experience'] = instance.experience
        day['games'] = instance.games
        day['minutes'] = instance.minutes
        daily[instance.created_at] = day
      end
      Player.where(name: name).delete_all
      Player.create!(playerid: playerid,
                     name: name,
                     age: age,
                     quality: quality,
                     potential: potential,
                     team: team,
                     daily: daily)
    end

    remove_column :players, :ai
    remove_column :players, :stadium
    remove_column :players, :goalie
    remove_column :players, :defense
    remove_column :players, :offense
    remove_column :players, :shooting
    remove_column :players, :passing
    remove_column :players, :speed
    remove_column :players, :strength
    remove_column :players, :selfcontrol
    remove_column :players, :playertype
    remove_column :players, :experience
    remove_column :players, :games
    remove_column :players, :minutes
  end
end
