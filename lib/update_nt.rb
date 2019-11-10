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
        begin # rubocop:disable Style/RedundantBegin
          update_player row_num
        rescue Nokogiri::XML::XPath::SyntaxError
          redo
        end
      end
    end

    def update_player(row_num)
      # mark player as deleted if he doesn't exist anymore
      return if !State.update_row?(row_num) || player_retired?

      # update player attributes and click on team name link
      update_nt_player_attributes

      # go to player's team's stadium page
      go_to_stadium_page

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

    def go_to_stadium_page
      team_id = @agent.current_page.uri.to_s[77..-1]
      @agent.get(
        "http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{team_id}"
      )
    end

    def update_nt_player_stadium
      stadium_attributes = @agent.page.search('.sr1 .yspscores').map { |area| area.text.strip }

      # stadium training
      stadium_training = stadium_attributes[3]
      WsRow.stadium = stadium_training[0] == '0' ? 0 : stadium_training[0..2]
    end

    def update_nt_player_in_db
      nt_player = Player.find_by(playerid: WsRow.id, team: State.team)
      datetime = Time.now.in_time_zone('Eastern Time (US & Canada)')
      if nt_player.nil?
        create_nt_player datetime
      else
        update_nt_player nt_player, datetime
      end
    end

    def create_nt_player(datetime)
      Player.create!(
        playerid: WsRow.id, name: WsRow.name, age: WsRow.age, quality: WsRow.quality,
        potential: WsRow.potential, team: State.team, playertype: WsRow.playertype,
        daily: { datetime => WsRow.daily_row })
    end

    def update_nt_player(nt_player, datetime)
      ai_hash = nt_player['daily']
      ai_hash[datetime] = WsRow.daily_row
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
