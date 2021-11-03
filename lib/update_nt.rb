module UpdateNT
  class << UpdateNT
    def run(agent, sheet, team)
      @agent = agent
      State.sheet = sheet
      State.team = team
      update_national_team
    end

    private

    def update_national_team
      (2..State.sheet.num_rows).each do |row_num|
        State.row = row_num
        update_player
      rescue Nokogiri::XML::XPath::SyntaxError
        redo
      end
    end

    def update_player
      # mark player as deleted if he doesn't exist anymore
      return if player_retired?

      # update player attributes and click on team name link
      update_nt_player_attributes

      # if u23, go to main team's page
      u23_check

      # update player's team stadium
      update_nt_player_stadium

      # create or update player in db
      update_nt_player_in_db

      synchronize_sheet
    end

    def player_retired?
      @agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{WsRow.id}")
      if @agent.page.content.include? 'Player does not exist or has retired !'
        WsRow.mark_player_as_deleted
        return true
      end
      false
    end

    def update_nt_player_attributes
      page = @agent.page
      player_attributes = page.search('.q1, .q').map(&:text)
      player = NtPlayer.new(player_attributes)

      WsRow.update_row player

      player_team = player_attributes[5]
      page.link_with(text: player_team).click
    end

    def u23_check
      page = @agent.page
      # check if u23 team
      return unless page.image_urls.any? { |img| img.path.include?('nat68.gif') }

      # get manager
      manager_link = page.links.find { |link| link_text_includes?(link, 'manager_info.php') && link.text != 'Info' }
      return unless manager_link

      # go to manager page
      u23_team_id = team_id
      manager_link.click
      go_to_main_team u23_team_id
    end

    def go_to_main_team(u23_team_id)
      team_links = @agent.page.links.select do |link|
        link_text_includes? link, 'public_team_info_basic.php'
      end
      current_team = team_links.find do |link|
        link_text_includes? link, "public_team_info_basic.php&team_id=#{u23_team_id}"
      end
      if current_team.text.upcase == 'A U23'
        team_links.first.click
      else
        team_links.second.click
      end
    end

    def link_text_includes?(link, text)
      link.uri.query&.include?(text)
    end

    def team_id
      @agent.current_page.uri.to_s[78..]
    end

    def update_nt_player_stadium
      @agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{team_id}")
      stadium_attributes = @agent.page.search('.sr1 .yspscores').map { |area| area.text.strip }

      # stadium training
      stadium_training = stadium_attributes[3]
      return if stadium_training.nil?

      WsRow.stadium = stadium_training[0] == '0' ? 0 : stadium_training[0..2]
    end

    def update_nt_player_in_db
      nt_player = Player.find_by(playerid: WsRow.id, team: State.team)
      if nt_player.nil?
        create_nt_player
      else
        update_nt_player nt_player
      end
    end

    def create_nt_player
      Player.create!(
        playerid: WsRow.id, name: WsRow.name, age: WsRow.age, quality: WsRow.quality, potential: WsRow.potential,
        team: State.team, playertype: WsRow.playertype, daily: { Time.zone.now => WsRow.daily_row })
    end

    def update_nt_player(nt_player)
      ai_hash = nt_player['daily']
      ai_hash[Time.zone.now] = WsRow.daily_row
      nt_player.update(
        age: WsRow.age, quality: WsRow.quality, potential: WsRow.potential,
        playertype: WsRow.playertype, daily: ai_hash)
    end

    def synchronize_sheet
      State.sheet.synchronize # save and reload
    rescue GoogleDrive::Error
      puts "**********GOOGLE DRIVE ERROR SYNCING: #{ws.name}**********"
    end
  end
end
