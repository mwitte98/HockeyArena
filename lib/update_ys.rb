module UpdateYS
  class << UpdateYS
    def run(is_draft)
      @is_draft = is_draft
      update_ys
    end

    private

    def update_ys
      if State.version == 'live'
        @agent.get('http://www.hockeyarena.net/en/index.php?p=manager_youth_school_form.php')
      else
        @agent.get('http://beta.hockeyarena.net/en/index.php?p=manager_youth_school_form.php')
      end

      if @is_draft
        # don't update if draft and draft has happened
        return if @agent.page.search('#table-2 .thead td').size > 8
        search_string = '#table-2 tbody .center , #table-2 tbody .left , ' \
                        '#table-3 tbody .center , #table-3 tbody .left'
      else
        search_string = '#table-1 tbody td'
      end

      players = get_ys_players search_string

      remove_deleted_ys_players players

      update_ys_player_in_db players
    end

    def get_ys_players(search_string)
      players = []
      player_attributes = []
      count = 0

      # pull ys info from site
      @agent.page.search(search_string).each do |player_attribute|
        count += 1
        if count < 7
          stripped_text = player_attribute.text.strip
          player_attributes << (count == 2 || count == 5 ? stripped_text : stripped_text[1..-1])
        elsif end_of_ys_row?(count)
          players << player_attributes
          player_attributes = []
          count = 0
        end
      end

      players
    end

    def end_of_ys_row?(count)
      (!@is_draft && count == 9) || (@is_draft && count == 8)
    end

    def remove_deleted_ys_players(players)
      manager = State.manager
      version = State.version
      names = []
      players.each { |player| names << player[0] }

      # Names of all players that have been tracked
      names_in_db = []
      players_in_db = YouthSchool.where(manager: manager, version: version, draft: @is_draft)
      players_in_db.each { |player| names_in_db << player['name'] }

      # Delete players from db that have been deleted on HA
      names_in_db.each do |name|
        unless names.include?(name)
          YouthSchool.find_by(name: name, manager: manager, version: version, draft: @is_draft)
                     .delete
        end
      end
    end

    def update_ys_player_in_db(players)
      manager = State.manager
      version = State.version
      player_priority = 1
      players.each do |player|
        name = player[0]
        ys_player =
          YouthSchool.find_by(name: name, manager: manager, version: version, draft: @is_draft)
        if ys_player.nil?
          YouthSchool.create!(name: name, age: player[1], quality: player[2],
                              potential: player[3], talent: player[4],
                              ai: {
                                Time.now.in_time_zone('Eastern Time (US & Canada)') => player[5]
                              },
                              priority: player_priority, manager: manager,
                              version: version, draft: @is_draft)
        else
          update_ys_player(player, ys_player, player_priority)
        end
        player_priority += 1
      end
    end

    def update_ys_player(player, ys_player, player_priority)
      ai_hash = ys_player['ai']
      datetime = Time.now.in_time_zone('Eastern Time (US & Canada)')
      ai_hash[datetime] = player[5]
      ys_player.update(age: player[1], quality: player[2], potential: player[3],
                       talent: player[4], ai: ai_hash, priority: player_priority)
    end
  end
end
