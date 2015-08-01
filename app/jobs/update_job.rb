class UpdateJob
  include SuckerPunch::Job
  require 'active_support/core_ext'
  require 'google/api_client'

  client = Google::APIClient.new
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
  @@doc5960 = @@session.spreadsheet_by_key(ENV['5960_key'])
  @@ws19 = @@doc5960.worksheet_by_title('Players19')
  @@doc6162 = @@session.spreadsheet_by_key(ENV['6162_key'])
  @@ws17 = @@doc6162.worksheet_by_title('Players17')
  @@docNT = @@session.spreadsheet_by_key(ENV['NT_key'])
  @@wsNT = @@docNT.worksheet_by_title('Season 59')
  @@docYS = @@session.spreadsheet_by_key(ENV['YS_key'])
  @@total_players = @@ws19.num_rows + @@ws17.num_rows + @@wsNT.num_rows - 3
  @@player_number = 0

  def perform
    login_to_HA('speedysportwhiz', 'live')
    update_u20('speedysportwhiz', @@ws19)
    update_u20('speedysportwhiz', @@ws17)
    update_nt('speedysportwhiz', @@wsNT)
    update_ys('speedysportwhiz', 'live', false)
    update_ys('speedysportwhiz', 'live', true)
    login_to_HA('magicspeedo', 'live')
    update_u20('magicspeedo', @@ws17)
    update_nt('magicspeedo', @@wsNT)
    update_ys('magicspeedo', 'live', false)
    update_ys('magicspeedo', 'live', true)
    login_to_HA('speedysportwhiz', 'beta')
    update_ys('speedysportwhiz', 'beta', false)
    update_ys('speedysportwhiz', 'beta', true)
    login_to_HA('magicspeedo', 'beta')
    update_ys('magicspeedo', 'beta', false)
    update_ys('magicspeedo', 'beta', true)
  end

  private
  
    def login_to_HA(mgr, version)
      # Login to HA
      Pusher.trigger('players_channel', 'update', { message: "Logging into #{version} Hockey Arena as #{mgr}", progress: 0 })
      @@agent = Mechanize.new
      if version == "live"
        @@agent.get('http://www.hockeyarena.net/en/')
      else
        @@agent.get('http://beta.hockeyarena.net/en/')
      end
      form = @@agent.page.forms.first
      form.nick = mgr
      if version == "live"
        form.password = ENV['HA_password']
      else
        form.password = ENV['beta_password']
      end
      form.submit
    end
  
    def update_u20(mgr, ws)
      # Update ws
      for a in 2..ws.num_rows
        if mgr == 'speedysportwhiz' && ws[a,29] != 'y'
          @@player_number += 1
          string = "Updating #{ws[a,1]} (#{@@player_number} of #{@@total_players})"
          Pusher.trigger('players_channel', 'update', { message: string, progress: 0 })
          begin
            @@agent = update_u20_player(ws, a, @@agent, false)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            puts "**********Happening here in first loop: #{ws[a,1]}**********"
            @@player_number -= 1
            redo
          end
        elsif mgr == 'magicspeedo' && ws[a,29] == 'y'
          @@player_number += 1
          string = "Updating #{ws[a,1]} (#{@@player_number} of #{@@total_players})"
          Pusher.trigger('players_channel', 'update', { message: string, progress: 0 })
          begin
            @@agent = update_u20_player(ws, a, @@agent, true)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            puts "**********Happening here in first loop: #{ws[a,1]}**********"
            @@player_number -= 1
            redo
          end
        end
      end
    end
    
    def update_nt(mgr, ws)
      # Update ws
      for a in 2..ws.num_rows
        if mgr == 'speedysportwhiz' && ws[a,29] == 'y'
          @@player_number += 1
          string = "Updating #{ws[a,1]} (#{@@player_number} of #{@@total_players})"
          Pusher.trigger('players_channel', 'update', { message: string, progress: 0 })
          begin
            @@agent = update_nt_player(ws, a, @@agent, false)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            puts "**********Happening here in first loop: #{ws[a,1]}**********"
            @@player_number -= 1
            redo
          end
        elsif mgr == 'magicspeedo' && ws[a,29] != 'y'
          @@player_number += 1
          string = "Updating #{ws[a,1]} (#{@@player_number} of #{@@total_players})"
          Pusher.trigger('players_channel', 'update', { message: string, progress: 0 })
          begin
            @@agent = update_nt_player(ws, a, @@agent, true)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            puts "**********Happening here in first loop: #{ws[a,1]}**********"
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

    def update_u20_player(ws, i, agent, asst)
      id = ws[i,28]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{id}")

      player_info = []
      agent.page.search('.q1, .q').each do |info|
        player_info << info.text
      end

      ws[i,2] = player_info[0] #ai

      if player_info.size > 35 #player is scouted
        ws[i,7] = strip_percent(player_info[16]) #goa
        ws[i,8] = strip_percent(player_info[18]) #def
        ws[i,9] = strip_percent(player_info[20]) #off
        ws[i,10] = strip_percent(player_info[22]) #shot
        ws[i,11] = strip_percent(player_info[24]) #pass
        ws[i,12] = strip_percent(player_info[17]) #spd
        ws[i,13] = strip_percent(player_info[19]) #str
        ws[i,14] = strip_percent(player_info[21]) #sco
        ws[i,16] = strip_percent(player_info[25]) #exp

        if (!asst && player_info[5] == 'RIT Tigers') || (asst && player_info[5] == 'McDeedo Punch')
          ws[i,21] = player_info[34] #games
          ws[i,22] = player_info[36] #min
        else
          ws[i,21] = player_info[31] #games
          ws[i,22] = player_info[33] #min
        end
      else #player isn't scouted
        ws[i,21] = player_info[19] #games
        ws[i,22] = player_info[21] #min
      end

      if agent.page.link_with(:text => player_info[5]).nil?
        for a in 2..27
          ws[i,a] = "DELETE"
        end
      else
        agent.page.link_with(:text => player_info[5]).click
      end
      team_id = agent.page.uri.to_s[77..-1]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{team_id}")
      stadium_info = []
      agent.page.search('.sr1 .yspscores').each do |info|
        stadium_info << info.text.strip
      end

      if stadium_info[3][0] == '0' #stadium-training
        ws[i,5] = 0
      else
        ws[i,5] = stadium_info[3][0..2]
      end

      Player.create!(playerid: ws[i,28], name: ws[i,1], age: player_info[2], ai: ws[i,2], quality: ws[i,3], potential: ws[i,4],
        stadium: ws[i,5], goalie: ws[i,7], defense: ws[i,8], offense: ws[i,9], shooting: ws[i,10], passing: ws[i,11], speed: ws[i,12],
        strength: ws[i,13], selfcontrol: ws[i,14], playertype: ws[i,15], experience: ws[i,16], games: ws[i,21], minutes: ws[i,22])

      begin
        ws.synchronize #save and reload
      rescue GoogleDrive::Error => e
        puts "**********GOOGLE DRIVE ERROR SYNCING: #{ws[i,1]}**********"
      end

      agent
    end
    
    def update_nt_player(ws, i, agent, asst)
      id = ws[i,28]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{id}")

      player_info = []
      agent.page.search('.q1, .q').each do |info|
        player_info << info.text
      end
      
      ws[i,2] = player_info[2] #age
      ws[i,3] = player_info[0] #ai

      if player_info.size > 35 #player is scouted
        ws[i,8] = strip_percent(player_info[16]) #goa
        ws[i,9] = strip_percent(player_info[18]) #def
        ws[i,10] = strip_percent(player_info[20]) #off
        ws[i,11] = strip_percent(player_info[22]) #shot
        ws[i,12] = strip_percent(player_info[24]) #pass
        ws[i,13] = strip_percent(player_info[17]) #spd
        ws[i,14] = strip_percent(player_info[19]) #str
        ws[i,15] = strip_percent(player_info[21]) #sco
        ws[i,17] = strip_percent(player_info[25]) #exp

        if (!asst && player_info[5] == 'RIT Tigers') || (asst && player_info[5] == 'McDeedo Punch')
          ws[i,22] = player_info[34] #games
          ws[i,23] = player_info[36] #min
        else
          ws[i,22] = player_info[31] #games
          ws[i,23] = player_info[33] #min
        end
      else #player isn't scouted
        ws[i,22] = player_info[19] #games
        ws[i,23] = player_info[21] #min
      end

      if agent.page.link_with(:text => player_info[5]).nil?
        for a in 2..27
          ws[i,a] = "DELETE"
        end
      else
        agent.page.link_with(:text => player_info[5]).click
      end
      team_id = agent.page.uri.to_s[77..-1]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{team_id}")
      stadium_info = []
      agent.page.search('.sr1 .yspscores').each do |info|
        stadium_info << info.text.strip
      end

      if stadium_info[3][0] == '0' #stadium-training
        ws[i,6] = 0
      else
        ws[i,6] = stadium_info[3][0..2]
      end

      begin
        ws.synchronize #save and reload
      rescue GoogleDrive::Error => e
        puts "**********GOOGLE DRIVE ERROR SYNCING: #{ws[i,1]}**********"
      end

      agent
    end
    
    def update_ys(mgr, version, draft)
      # Update youth school
      Pusher.trigger('players_channel', 'update', { message: "Updating #{mgr} #{version} YS and draft", progress: 0 })
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
          YouthSchool.create!(name: player[0], age: player[1], quality: player[2], potential: player[3], talent: player[4],
            ai: { DateTime.now => player[5] }, priority: player_priority, manager: mgr, version: version, draft: draft)
        else
          ai_hash = player_in_db["ai"]
          ai_hash[DateTime.now] = player[5]
          player_in_db.update(age: player[1], quality: player[2], potential: player[3], talent: player[4], ai: ai_hash, priority: player_priority)
        end
        player_priority += 1
      end
    end
end