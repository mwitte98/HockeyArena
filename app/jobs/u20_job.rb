class U20Job
  include SuckerPunch::Job

  def perform()
  	#Login to Google
    Pusher.trigger('players_channel', 'update', { message: "Logging into Google Docs", progress: 0 })
    session = GoogleDrive.login(ENV['google_email'], ENV['google_password'])
    doc5354 = session.spreadsheet_by_key(ENV['5354_key'])
    ws20 = doc5354.worksheet_by_title("20")
    doc5556 = session.spreadsheet_by_key(ENV['5556_key'])
    ws18 = doc5556.worksheet_by_title("Players18")
    ws_cuts = doc5556.worksheet_by_title("Cuts")
    total_players = ws20.num_rows() + ws18.num_rows() + ws_cuts.num_rows() - 3

    #Login to HA
    Pusher.trigger('players_channel', 'update', { message: "Logging into Hockey Arena", progress: 0 })
    agent = Mechanize.new
    agent.get("http://www.hockeyarena.net/en/")
    form = agent.page.forms.first
    form.nick = ENV['HA_nick']
    form.password = ENV['HA_password']
    form.submit

    for i in 2..ws20.num_rows()
      player_number = i - 1
      string = "Updating #{ws20[i,1]} (#{player_number} of #{total_players})"
      Pusher.trigger('players_channel', 'update', { message: string, progress: (i-1.0)/total_players*100 })
      agent = update_player(ws20, i, agent)
    end

    for a in 2..ws18.num_rows()
      player_number = ws20.num_rows() + a - 2
      string = "Updating #{ws18[a,1]} (#{player_number} of #{total_players})"
      Pusher.trigger('players_channel', 'update', { message: string, progress: (ws20.num_rows()+a-2.0)/total_players*100 })
      agent = update_player(ws18, a, agent)
    end

    for b in 2..ws_cuts.num_rows()
      player_number = ws20.num_rows() + ws18.num_rows() + b - 3
      string = "Updating #{ws_cuts[b,1]} (#{player_number} of #{total_players})"
      Pusher.trigger('players_channel', 'update', { message: string, progress: (ws20.num_rows()+ws18.num_rows()+b-3.0)/total_players*100 })
      agent = update_player(ws_cuts, b, agent)
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
      id = ws[i,27]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{id}")

      player_info = []
      agent.page.search(".q").each do |info|
        player_info << info.text.strip
      end

      ws[i,2] = player_info[8] #ai

      if player_info.size > 35 #player is scouted
        ws[i,7] = strip_percent(player_info[14]) #goa
        ws[i,8] = strip_percent(player_info[16]) #def
        ws[i,9] = strip_percent(player_info[18]) #off
        ws[i,10] = strip_percent(player_info[20]) #shot
        ws[i,11] = strip_percent(player_info[22]) #pass
        ws[i,12] = strip_percent(player_info[15]) #spd
        ws[i,13] = strip_percent(player_info[17]) #str
        ws[i,14] = strip_percent(player_info[19]) #sco
        ws[i,16] = strip_percent(player_info[23]) #exp

        if player_info[3] == "RIT Tigers"
          ws[i,21] = player_info[32] #games
          ws[i,22] = player_info[34] #min
        else
          ws[i,21] = player_info[29] #games
          ws[i,22] = player_info[31] #min
        end
      else #player isn't scouted
        ws[i,21] = player_info[17] #games
        ws[i,22] = player_info[19] #min
      end

      agent.page.link_with(:text => player_info[3]).click
      teamid = agent.page.uri.to_s[77..-1]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{teamid}")
      stadium_info = []
      agent.page.search(".sr1 .yspscores").each do |info|
        stadium_info << info.text.strip
      end
      ws[i,5] = stadium_info[3][0..2] #stadium

      ws.synchronize() #save and reload

      return agent
    end
end