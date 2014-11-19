class U20Job
  include SuckerPunch::Job

  def perform()
  	#Login to Google
    Pusher.trigger('players_channel', 'update', { message: "Logging into Google Docs", progress: 0 })
    session = GoogleDrive.login(ENV['google_email'], ENV['google_password'])
    doc5556 = session.spreadsheet_by_key(ENV['5556_key'])
    ws18 = doc5556.worksheet_by_title("Players20")
    doc5758 = session.spreadsheet_by_key(ENV['5758_key'])
    ws17 = doc5758.worksheet_by_title("Players18")
    total_players = ws18.num_rows() + ws17.num_rows() - 2

    #Login to HA
    Pusher.trigger('players_channel', 'update', { message: "Logging into Hockey Arena", progress: 0 })
    agent = Mechanize.new
    agent.get("http://www.hockeyarena.net/en/")
    form = agent.page.forms.first
    form.nick = ENV['HA_nick']
    form.password = ENV['HA_password']
    form.submit

    for a in 2..ws18.num_rows()
      player_number = a - 1
      string = "Updating #{ws18[a,1]} (#{player_number} of #{total_players})"
      Pusher.trigger('players_channel', 'update', { message: string, progress: (a-1.0)/total_players*100 })
      begin
        agent = update_player(ws18, a, agent)
      rescue Nokogiri::XML::XPath::SyntaxError => e
        puts "**********Happening here in first loop: #{ws18[a,1]}**********"
      end
    end

    for b in 2..ws17.num_rows()
      player_number = ws18.num_rows() + b - 2
      string = "Updating #{ws17[b,1]} (#{player_number} of #{total_players})"
      Pusher.trigger('players_channel', 'update', { message: string, progress: (ws18.num_rows()+b-2.0)/total_players*100 })
      begin
        agent = update_player(ws17, b, agent)
      rescue Nokogiri::XML::XPath::SyntaxError => e
        puts "**********Happening here in second loop: #{ws17[b,1]}**********"
      end
    end

    Pusher.trigger('players_channel', 'update', { message: "", progress: 0 })
  end

  private

    def strip_percent(value)
      if value[2] == "("
        return value[0]
      elsif value[3] == "("
        return value[0..1]
      elsif value[4] == "("
        return value[0..2]
      else
        return value
      end
    end

    def update_player(ws, i, agent)
      id = ws[i,28]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{id}")

      player_info = []
      agent.page.search(".q1, .q").each do |info|
        player_info << info.text.strip
      end

      ws[i,2] = player_info[0] #ai

      # FIX THIS SIZE VALUE
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

        if player_info[5] == "RIT Tigers"
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

      agent.page.link_with(:text => player_info[5]).click
      teamid = agent.page.uri.to_s[77..-1]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{teamid}")
      stadium_info = []
      agent.page.search(".sr1 .yspscores").each do |info|
        stadium_info << info.text.strip
      end

      if stadium_info[3][0] == "0" #stadium-training
      	ws[i,5] = 0
      else
        ws[i,5] = stadium_info[3][0..2]
      end

      Player.create!(playerid: ws[i,28], name: ws[i,1], age: player_info[2], ai: ws[i,2], quality: ws[i,3], potential: ws[i,4],
        stadium: ws[i,5], goalie: ws[i,7], defense: ws[i,8], offense: ws[i,9], shooting: ws[i,10], passing: ws[i,11], speed: ws[i,12],
        strength: ws[i,13], selfcontrol: ws[i,14], playertype: ws[i,15], experience: ws[i,16], games: ws[i,21], minutes: ws[i,22])

      begin
        ws.synchronize() #save and reload
      rescue GoogleDrive::Error => e
        puts "**********GOOGLE DRIVE ERROR SYNCING: #{ws[i,1]}**********"
      end

      return agent
    end
end