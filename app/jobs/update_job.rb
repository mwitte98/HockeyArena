class UpdateJob
  include SuckerPunch::Job
  require 'active_support/core_ext'
  require 'google/api_client'

  client = Google::APIClient.new({application_name: 'HockeyArena', application_version: '0.0.0.0'})
  key = OpenSSL::PKey::RSA.new ENV['google_private_key'], ENV['google_secret']
  client.authorization = Signet::OAuth2::Client.new(
    :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
    :audience => 'https://accounts.google.com/o/oauth2/token',
    :scope => "https://docs.google.com/feeds/ " +
      "https://docs.googleusercontent.com/ " +
      "https://spreadsheets.google.com/feeds/",
    :issuer => ENV['google_issuer'],
    :signing_key => key)
  @@session = GoogleDrive.login_with_oauth(client.authorization.fetch_access_token!["access_token"])
  @@doc6364 = @@session.spreadsheet_by_key(ENV['6364_key'])
  @@ws19 = @@doc6364.worksheet_by_title('Players19')
  @@doc6566 = @@session.spreadsheet_by_key(ENV['6566_key'])
  @@ws17 = @@doc6566.worksheet_by_title('Players17')
  @@docNT = @@session.spreadsheet_by_key(ENV['NT_key'])
  @@wsNT = @@docNT.worksheet_by_title('Season 63')
  @@total_players = @@ws19.num_rows + @@ws17.num_rows + @@wsNT.num_rows - 3
  @@player_number = 0
  @@login_attempt = 1
  @@goodToGo = false

  def perform
    login_to_HA('speedysportwhiz', 'live')
    if @@goodToGo
      update_team('speedysportwhiz', @@ws19, '6364')
      update_team('speedysportwhiz', @@ws17, '6566')
      update_team('speedysportwhiz', @@wsNT, 'senior')
      update_ys('speedysportwhiz', 'live', false)
      update_ys('speedysportwhiz', 'live', true)
    end
    
    login_to_HA('magicspeedo', 'live')
    if @@goodToGo
      update_team('magicspeedo', @@ws17, '6566')
      update_team('magicspeedo', @@wsNT, 'senior')
      update_ys('magicspeedo', 'live', false)
      update_ys('magicspeedo', 'live', true)
    end
    
    login_to_HA('speedysportwhiz', 'beta')
    if @@goodToGo
      update_ys('speedysportwhiz', 'beta', false)
      update_ys('speedysportwhiz', 'beta', true)
    end
    
    login_to_HA('magicspeedo', 'beta')
    if @@goodToGo
      update_ys('magicspeedo', 'beta', false)
      update_ys('magicspeedo', 'beta', true)
    end
    
    Pusher.trigger('players_channel', 'update', { message: "", progress: 0 })
  end

  private
  
    def login_to_HA(mgr, version)
      # Login to HA
      Pusher.trigger('players_channel', 'update', { message: "Logging into #{version} Hockey Arena as #{mgr}",
                                                    progress: (@@player_number.to_f/@@total_players.to_f*100.0).to_i })
      @@login_attempt = 1
      @@goodToGo = false
      @@agent = Mechanize.new
      if version == "live"
        @@agent.get('http://www.hockeyarena.net/en/')
        form = @@agent.page.forms.first
        form.nick = mgr
        form.password = ENV['HA_password']
        form.submit
      else
        @@agent.get('http://beta.hockeyarena.net/en/')
        form = @@agent.page.forms.first
        form.nick = mgr
        form.password = ENV['beta_password']
        form.submit
      end
      sleep 1
      if @@agent.page.content.include?("Logout")
        @@goodToGo = true
      else
        puts "*****Login #{@@login_attempt} to HA failed for #{mgr} #{version}. Attempting to try again.*****"
        @@agent.page.search('#page').each do |info|
          puts info.text
        end
        @@login_attempt += 1
        if @@login_attempt <= 2
          login_to_HA(mgr, version)
        end
      end
    end
  
    def update_team(mgr, ws, team)
      # Update team
      for a in 2..ws.num_rows
        if ((team != 'senior' && mgr == 'speedysportwhiz' && ws[a,29] != 'y') ||
          (team != 'senior' && mgr == 'magicspeedo' && ws[a,29] == 'y') ||
          (team == 'senior' && mgr == 'speedysportwhiz' && ws[a,29] == 'y') ||
          (team == 'senior' && mgr == 'magicspeedo' && ws[a,29] != 'y'))
          @@player_number += 1
          string = "Updating #{ws[a,1]} (#{@@player_number} of #{@@total_players})"
          Pusher.trigger('players_channel', 'update', { message: string, progress: (@@player_number.to_f/@@total_players.to_f*100.0).to_i })
          begin
            @@agent = update_player(ws, team, a, @@agent, mgr)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            @@player_number -= 1
            redo
          end
        end
      end
    end
    
    def strip_percent(value)
      if value[2] == '('
        return value[0]
      elsif value[3] == '('
        return value[0..1]
      elsif value[4] == '('
        return value[0..2]
      else
        return value
      end
    end

    def update_player(ws, team, row, agent, mgr)
      col = team == "senior" ? 1 : 0
      id = ws[row,28]
      
      # don't update if there's no id
      return agent if id == '';
      
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{id}")
      if agent.page.content.include? "Player does not exist or has retired !"
        for a in 2..27
          ws[row,a] = "DELETE"
        end
        return agent
      end
      
      player_info = []
      agent.page.search('.q1, .q').each do |info|
        player_info << info.text
      end

      if team == "senior"
        ws[row,2] = player_info[2] #age
      end
      ws[row,2+col] = player_info[0] #ai

      if player_info.size > 35 #player is scouted
        ws[row,7+col] = strip_percent(player_info[16]) #goa
        ws[row,8+col] = strip_percent(player_info[18]) #def
        ws[row,9+col] = strip_percent(player_info[20]) #off
        ws[row,10+col] = strip_percent(player_info[22]) #shot
        ws[row,11+col] = strip_percent(player_info[24]) #pass
        ws[row,12+col] = strip_percent(player_info[17]) #spd
        ws[row,13+col] = strip_percent(player_info[19]) #str
        ws[row,14+col] = strip_percent(player_info[21]) #sco
        ws[row,16+col] = strip_percent(player_info[25]) #exp

        if (mgr == 'speedysportwhiz' && player_info[5] == 'RIT Tigers') || (mgr == 'magicspeedo' && player_info[5] == 'I WILL NOT RESIGN FREE AGENTS')
          ws[row,21+col] = player_info[34] #games
          ws[row,22+col] = player_info[36] #min
        else
          ws[row,21+col] = player_info[31] #games
          ws[row,22+col] = player_info[33] #min
        end
      else #player isn't scouted
        ws[row,21+col] = player_info[19] #games
        ws[row,22+col] = player_info[21] #min
      end

      agent.page.link_with(:text => player_info[5]).click
      team_id = agent.page.uri.to_s[77..-1]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{team_id}")
      stadium_info = []
      agent.page.search('.sr1 .yspscores').each do |info|
        stadium_info << info.text.strip
      end

      if stadium_info[3][0] == '0' #stadium-training
        ws[row,5+col] = 0
      else
        ws[row,5+col] = stadium_info[3][0..2]
      end
      
      player_in_db = Player.find_by({ name: ws[row,1], team: team })
      if player_in_db.nil?
        Player.create!(
          playerid: ws[row,28],
          name: ws[row,1],
          age: player_info[2],
          quality: ws[row,3+col],
          potential: ws[row,4+col],
          team: team,
          daily: {
            DateTime.now.in_time_zone('Eastern Time (US & Canada)') => {
              ai: ws[row,2+col].to_i,
              stadium: ws[row,5+col].to_i,
              goalie: ws[row,7+col].to_i,
              defense: ws[row,8+col].to_i,
              offense: ws[row,9+col].to_i,
              shooting: ws[row,10+col].to_i,
              passing: ws[row,11+col].to_i,
              speed: ws[row,12+col].to_i,
              strength: ws[row,13+col].to_i,
              selfcontrol: ws[row,14+col].to_i,
              playertype: ws[row,15+col],
              experience: ws[row,16+col].to_i,
              games: ws[row,21+col].to_i,
              minutes: ws[row,22+col].to_i
            }
          }
        )
      else
          ai_hash = player_in_db["daily"]
          ai_hash[DateTime.now.in_time_zone('Eastern Time (US & Canada)')] = {
            ai: ws[row,2+col].to_i,
            stadium: ws[row,5+col].to_i,
            goalie: ws[row,7+col].to_i,
            defense: ws[row,8+col].to_i,
            offense: ws[row,9+col].to_i,
            shooting: ws[row,10+col].to_i,
            passing: ws[row,11+col].to_i,
            speed: ws[row,12+col].to_i,
            strength: ws[row,13+col].to_i,
            selfcontrol: ws[row,14+col].to_i,
            playertype: ws[row,15+col],
            experience: ws[row,16+col].to_i,
            games: ws[row,21+col].to_i,
            minutes: ws[row,22+col].to_i
          }
          player_in_db.update(age: player_info[2], quality: ws[row,3+col], potential: ws[row,4+col], daily: ai_hash)
      end
        
      begin
        ws.synchronize #save and reload
      rescue GoogleDrive::Error => e
        puts "**********GOOGLE DRIVE ERROR SYNCING: #{ws[row,1]}**********"
      end

      agent
    end
    
    def update_ys(mgr, version, draft)
      # Update youth school
      Pusher.trigger('players_channel', 'update', { message: "Updating #{mgr} #{version} YS and draft",
                                                    progress: (@@player_number.to_f/@@total_players.to_f*100.0).to_i })
      ys_info = []
      player_info = []
      count = 0
      if version == "live"
        @@agent.get("http://www.hockeyarena.net/en/index.php?p=manager_youth_school_form.php")
      else
        @@agent.get("http://beta.hockeyarena.net/en/index.php?p=manager_youth_school_form.php")
      end
      if draft
        search_string = '#table-2 tbody .center , #table-2 tbody .left , #table-3 tbody .center , #table-3 tbody .left'
      else
        search_string = '#table-1 tbody td'
      end
      @@agent.page.search(search_string).each do |info| # Pull YS info from site
        count += 1
        if count > 0 && count < 7
          if count == 2 || count == 5
            player_info << info.text.strip
          else
            player_info << info.text.strip[1..-1]
          end
        elsif (!draft and count == 9) or (draft and count == 8)
          ys_info << player_info
          count = 0
          player_info = []
        end
      end

      names = []
      ys_info.each do |player|
        names << player[0]
      end

      # Names of all players that have been tracked
      names_in_doc = []
      players_in_doc = YouthSchool.where({ manager: mgr, version: version, draft: draft })
      players_in_doc.each do |player|
        names_in_doc << player["name"]
      end
      
      #Delete players from db that have been deleted on HA
      names_in_doc.each do |name|
        if not names.include?(name)
          YouthSchool.find_by({ name: name, manager: mgr, version: version, draft: draft }).delete
        end
      end
      
      #Add new day to db
      player_priority = 1
      ys_info.each do |player|
        player_in_db = YouthSchool.find_by({ name: player[0], manager: mgr, version: version, draft: draft })
        if player_in_db.nil?
          YouthSchool.create!(name: player[0],
                              age: player[1],
                              quality: player[2],
                              potential: player[3],
                              talent: player[4],
                              ai: { DateTime.now.in_time_zone('Eastern Time (US & Canada)') => player[5] },
                              priority: player_priority,
                              manager: mgr,
                              version: version,
                              draft: draft)
        else
          ai_hash = player_in_db["ai"]
          ai_hash[DateTime.now.in_time_zone('Eastern Time (US & Canada)')] = player[5]
          player_in_db.update(age: player[1],
                              quality: player[2],
                              potential: player[3],
                              talent: player[4],
                              ai: ai_hash,
                              priority: player_priority)
        end
        player_priority += 1
      end
    end
end