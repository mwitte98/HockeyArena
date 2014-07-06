class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5354
    #@players = Player.order("ai DESC").all(:conditions => ["age != ?", 17])
    @players = []
  end

  def show5556
    #@players = Player.order("ai DESC").all(:conditions => ["age = ?", 17])
    @players = []
  end

  def login_HA
    
  end

  def get_info
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
      agent = update_player(ws20, i, agent)
      Pusher.trigger('players_channel', 'update', { message: "Updated #{ws20[i,1]}", progress: (i-1.0)/total_players*100 })
    end

    for a in 2..ws18.num_rows()
      agent = update_player(ws18, a, agent)
      Pusher.trigger('players_channel', 'update', { message: "Updated #{ws18[a,1]}", progress: (ws20.num_rows()+a-2.0)/total_players*100 })
    end

    for b in 2..ws_cuts.num_rows()
      agent = update_player(ws_cuts, b, agent)
      Pusher.trigger('players_channel', 'update', { message: "Updated #{ws_cuts[b,1]}", progress: (ws20.num_rows()+ws18.num_rows()+b-3.0)/total_players*100 })
    end

    redirect_to players5354_path
  end

  def get_NT_info
    #Login to Google
    Pusher.trigger('players_channel', 'update', { message: "Logging into Google Docs", progress: 0 })
    session = GoogleDrive.login(ENV['google_email'], ENV['google_password'])
    docNT = session.spreadsheet_by_key(ENV['NT_key'])
    wsNT = docNT.worksheet_by_title("Players")
    total_players = wsNT.num_rows()

    #Login to HA
    Pusher.trigger('players_channel', 'update', { message: "Logging into Hockey Arena", progress: 0 })
    agent = Mechanize.new
    agent.get("http://www.hockeyarena.net/en/")
    form = agent.page.forms.first
    form.nick = params[:username]
    form.password = params[:password]
    form.submit

    agent.get("http://www.hockeyarena.net/en/index.php?p=manager_summary.php")
    team_info = []
    agent.page.search(".right").each do |info|
      team_info << info.text.strip
    end
    my_team = team_info[3]

    for i in 2..total_players
      agent = update_NT_player(wsNT, my_team, i, agent)
      Pusher.trigger('players_channel', 'update', { message: "Updated #{wsNT[i,1]}", progress: (i-1.0)/total_players*100 })
    end

    redirect_to players5354_path
  end

  private

    def signed_in_user
      unless signed_in?
        flash[:warning] = "You must be signed in to access that page."
        redirect_to root_url
      end
    end

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

    def update_NT_player(ws, my_team, i, agent)
      id = ws[i,27]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{id}")

      player_info = []
      agent.page.search(".q").each do |info|
        player_info << info.text.strip
      end

      ws[i,2] = player_info[0] #age
      ws[i,3] = player_info[8] #ai

      if player_info.size > 35 #player is scouted
        ws[i,8] = strip_percent(player_info[14]) #goa
        ws[i,9] = strip_percent(player_info[16]) #def
        ws[i,10] = strip_percent(player_info[18]) #off
        ws[i,11] = strip_percent(player_info[20]) #shot
        ws[i,12] = strip_percent(player_info[22]) #pass
        ws[i,13] = strip_percent(player_info[15]) #spd
        ws[i,14] = strip_percent(player_info[17]) #str
        ws[i,15] = strip_percent(player_info[19]) #sco
        ws[i,17] = strip_percent(player_info[23]) #exp

        if player_info[3] == my_team
          ws[i,22] = player_info[32] #games
          ws[i,23] = player_info[34] #min
        else
          ws[i,22] = player_info[29] #games
          ws[i,23] = player_info[31] #min
        end
      else #player isn't scouted
        ws[i,22] = player_info[17] #games
        ws[i,23] = player_info[19] #min
      end

      agent.page.link_with(:text => player_info[3]).click
      teamid = agent.page.uri.to_s[77..-1]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{teamid}")
      stadium_info = []
      agent.page.search(".sr1 .yspscores").each do |info|
        stadium_info << info.text.strip
      end
      ws[i,6] = stadium_info[3][0..2] #stadium

      ws.synchronize() #save and reload

      return agent
    end

end