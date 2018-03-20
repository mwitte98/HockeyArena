module UpdateYS
  class << UpdateYS
    def run(agent, team)
      @agent = agent
      @team = team
      go_to_ys_page
      update_ys false # update ys
      update_ys true # update draft
    end

    private

    def go_to_ys_page
      if State.version == 'live'
        @agent.get('http://www.hockeyarena.net/en/index.php?p=manager_youth_school_form.php')
      else
        @agent.get('http://beta.hockeyarena.net/en/index.php?p=manager_youth_school_form.php')
      end
    end

    def update_ys(is_draft)
      @is_draft = is_draft
      # don't update if draft and draft has happened
      return if @is_draft && @agent.page.search('#table-2 .thead td').size > 8

      # get data from page
      players = scrape_ys_players

      # delete players in db that are no longer in ys/draft
      remove_deleted_ys_players players

      # add current ai to db
      update_db players
    end

    def scrape_ys_players
      search_string = @is_draft ? '#table-3 tbody tr, #table-2 tbody tr' : '#table-1 tbody tr'

      players = @agent.page.search(search_string).map do |player|
        attributes = player.text.tr("\u00A0", ' ').strip.split("\r\n").map(&:strip)
        attributes - ['']
      end
      players
    end

    def remove_deleted_ys_players(players)
      names = players.map { |player| player[0] }

      # Names of all players that have been tracked
      names_in_db = find_ys_player_names

      # Delete players from db that have been deleted on HA
      (names_in_db - names).each { |name| find_ys_player(name).delete }
    end

    def find_ys_player_names
      YouthSchool.where(
        manager: State.manager, version: State.version, draft: @is_draft, team: @team
      ).pluck(:name)
    end

    def update_db(players)
      datetime = Time.now.in_time_zone('Eastern Time (US & Canada)')
      players.each do |player|
        ys_player = find_ys_player player[0]
        if ys_player.nil?
          create_ys_player player, datetime
        else
          update_ys_player player, ys_player, datetime
        end
      end
    end

    def find_ys_player(name)
      YouthSchool.find_by(
        name: name, manager: State.manager, version: State.version, draft: @is_draft, team: @team)
    end

    def create_ys_player(player, datetime)
      YouthSchool.create!(
        name: player[0], age: player[1], quality: player[2], potential: player[3],
        talent: player[4], ai: { datetime => player[5] },
        manager: State.manager, version: State.version, draft: @is_draft, team: @team)
    end

    def update_ys_player(player, ys_player, datetime)
      ai_hash = ys_player['ai']
      ai_hash[datetime] = player[5]
      ys_player.update(
        age: player[1], quality: player[2], potential: player[3], talent: player[4], ai: ai_hash)
    end
  end
end
