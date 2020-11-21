module UpdateYS
  class << UpdateYS
    def run(agent, ab_team)
      @agent = agent
      @ab_team = ab_team
      go_to_ys_page
      update_ys false # update ys
      update_ys true # update draft
    end

    private

    def go_to_ys_page
      prefix = State.version == 'live' ? 'www' : 'beta'
      @agent.get("http://#{prefix}.hockeyarena.net/en/index.php?p=manager_youth_school_form.php")
    end

    def update_ys(is_draft)
      @is_draft = is_draft

      # get data from page
      players = scrape_ys_players

      # delete players in db that are no longer in ys/draft
      remove_deleted_ys_players players

      # add current ai to db
      update_db players
    end

    def scrape_ys_players
      search_string = @is_draft ? '#table-3 tbody tr, #table-2 tbody tr' : '#table-1 tbody tr'

      @agent.page.search(search_string).map do |player|
        id = get_id player
        attributes = player.children.map(&:text).map { |text| text.tr("\u00A0", '') }.map(&:strip).reject(&:blank?)
        [id] + attributes
      end
    end

    def get_id(player)
      children = player.children.select { |child| child.class == Nokogiri::XML::Element }
      children.last.children.first.get_attribute 'id'
    end

    def remove_deleted_ys_players(players)
      ids = players.map { |player| player[0] }

      # IDs of all players that have been tracked
      ids_in_db = find_ys_player_ids

      # Delete players from db that have been deleted on HA
      (ids_in_db - ids).each { |id| find_ys_player(id).delete }
    end

    def find_ys_player_ids
      YouthSchool.where(
        manager: State.manager, version: State.version, draft: @is_draft, team: @ab_team
      ).pluck(:playerid)
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

    def find_ys_player(id)
      YouthSchool.find_by(
        playerid: id, manager: State.manager, version: State.version, draft: @is_draft, team: @ab_team
      )
    end

    def create_ys_player(player, datetime)
      YouthSchool.create!(
        playerid: player[0], name: player[1], age: player[2], quality: player[3],
        potential: player[4], talent: player[5], ai: { datetime => player[6] },
        manager: State.manager, version: State.version, draft: @is_draft, team: @ab_team)
    end

    def update_ys_player(player, ys_player, datetime)
      ai_hash = ys_player['ai']
      ai_hash[datetime] = player[6]
      ys_player.update(
        name: player[1], age: player[2], quality: player[3], potential: player[4], talent: player[5], ai: ai_hash)
    end
  end
end
