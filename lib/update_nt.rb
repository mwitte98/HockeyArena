module UpdateNT
  class << UpdateNT
    def run(sheet, team)
      State.sheet = sheet
      State.team = team
    end

    private

    def update_national_team
      (2..State.sheet.num_rows).each do |row_num|
        next unless State.update_row?(row_num)
        begin
          update_player
        rescue Nokogiri::XML::XPath::SyntaxError
          redo
        end
      end
    end

    def update_player
      # mark player as deleted if he doesn't exist anymore
      @agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{WsRow.id}")
      page = @agent.page
      if page.content.include? 'Player does not exist or has retired !'
        WsRow.mark_player_as_deleted
        return
      end

      # update player attributes and click on team name link
      update_nt_player_attributes

      # go to player's team's stadium page
      team_id = @agent.current_page.uri.to_s[77..-1]
      @agent.get(
        "http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{team_id}"
      )

      # update player's team stadium
      update_nt_player_stadium

      # create or update player in db
      update_nt_player_in_db

      begin
        State.sheet.synchronize # save and reload
      rescue GoogleDrive::Error
        puts "**********GOOGLE DRIVE ERROR SYNCING: #{ws.name}**********"
      end
    end

    def update_nt_player_attributes
      page = @agent.page
      player_attributes = []
      page.search('.q1, .q').each { |player_attribute| player_attributes << player_attribute.text }
      player = NtPlayer.new(player_attributes)

      WsRow.update_row player

      player_team = player_attributes[5]
      page.link_with(text: player_team).click
    end

    def update_nt_player_stadium
      stadium_attributes = []
      @agent.page.search('.sr1 .yspscores').each { |area| stadium_attributes << area.text.strip }

      # stadium training
      stadium_training = stadium_attributes[3]
      WsRow.stadium = stadium_training[0] == '0' ? 0 : stadium_training[0..2]
    end

    def update_nt_player_in_db
      player_name = WsRow.name
      id = WsRow.id
      team = State.team
      player_hash = WsRow.player_hash
      player_age = WsRow.age
      quality = WsRow.quality
      potential = WsRow.potential
      nt_player = Player.find_by(name: player_name, team: team)
      datetime = Time.now.in_time_zone('Eastern Time (US & Canada)')
      if nt_player.nil?
        Player.create!(playerid: id, name: player_name, age: player_age, quality: quality,
                       potential: potential, team: team, daily: { datetime => player_hash })
      else
        ai_hash = nt_player['daily']
        ai_hash[datetime] = player_hash
        nt_player.update(age: player_age, quality: quality, potential: potential, daily: ai_hash)
      end
    end
  end
end
