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
  @@docYS = @@session.spreadsheet_by_key(ENV['YS_key'])
  @@wsSpeedyYS = @@docYS.worksheet_by_title('speedy YS')
  @@wsMSYS = @@docYS.worksheet_by_title('MS YS')
  @@total_players = @@ws19.num_rows + @@ws17.num_rows - 2
  @@player_number = 0

  def perform
    update_U20_mgr
    ys_mgr(@@wsSpeedyYS)
    update_U20_asst
    ys_mgr(@@wsMSYS)
  end

  private

    def ys_mgr(ws)
      # Update my YS players
      ys_info = []
      player_info = []
      count = 0
      @@agent.get("http://www.hockeyarena.net/en/index.php?p=manager_youth_school_form.php")
      @@agent.page.search('#table-1 tbody td').each do |info| # Pull YS info from site
        count += 1
        if count > 0 && count < 7
          if count == 2 || count == 5
            player_info << info.text.strip
          else
            player_info << info.text.strip[1..-1]
          end
        elsif count == 9
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
      for a in 2..ws.num_rows
        names_in_doc << ws[a,1]
      end

      names_add = names - names_in_doc
      names_remove = names_in_doc - names

      # Remove info of deleted players from doc
      if !names_remove.empty?
        sheet_rows = ws.rows
        names_remove.each do |name|
          for a in 2..ws.num_rows
            if ws[a,1] == name
              rows_adding = sheet_rows.drop(a)
              ws.update_cells(a,1,rows_adding)
              for b in 1..ws.num_cols
                ws[ws.num_rows, b] = ''
              end
            end
          end
        end
      end

      # Add new players to the doc
      if !names_add.empty?
        sheet_rows = ws.rows(skip=1)
        add_num = names_add.size
        ws.update_cells(add_num+2,1,sheet_rows)
        for a in 2..(add_num+1)
          for b in 1..ws.num_cols
            ws[a,b] = ""
          end
          ws[a,1] = names_add[a-2]
        end
      end

      # TODO: Remove empty AI columns if oldest pull is removed

      # Update player info and add new AI
      for a in 0..(ys_info.size-1)
        ws[a+2,2] = ys_info[a][1] #age
        ws[a+2,3] = ys_info[a][2] #qua
        ws[a+2,4] = ys_info[a][3] #pot
        ws[a+2,5] = ys_info[a][4] #pos
        ai = ys_info[a][5]
        if ai.size == 7
          ai = ai[0..1]
        elsif ai.size == 8
          ai = ai[0..2]
        end
        ws[a+2,ws.num_cols-4] = ai #ai
      end

      # Update AI column header with date
      time = Time.now.getgm + 1.days
      ws[1,ws.num_cols-4] = "#{time.day}.#{time.month}"

      # Update formulas
      ws[1,ws.num_cols-3] = "Avg"
      ws[1,ws.num_cols-2] = "Min"
      ws[1,ws.num_cols-1] = "Med"
      ws[1,ws.num_cols] = "Max"
      ws[1,ws.num_cols+1] = " "
      num_cols = ws.num_cols
      for a in 2..ws.num_rows
        lastAiCell = RubyXL::Reference.ind2ref(a-1,num_cols-6)
        ws[a,num_cols-4] = "=AVERAGE(F#{a}:#{lastAiCell})"
        ws[a,num_cols-3] = "=MIN(F#{a}:#{lastAiCell})"
        ws[a,num_cols-2] = "=MEDIAN(F#{a}:#{lastAiCell})"
        ws[a,num_cols-1] = "=MAX(F#{a}:#{lastAiCell})"
        ws[a,num_cols] = "=IF(B#{a}=16,COUNTIF(F#{a}:#{lastAiCell},\">=40\"),IF(B#{a}=17,COUNTIF(F#{a}:#{lastAiCell},\">=70\"),IF(B#{a}=18,COUNTIF(F#{a}:#{lastAiCell},\">=100\"),0)))"
      end

      ws.synchronize
    end

    def update_U20_mgr
      # Login to Google
      Pusher.trigger('players_channel', 'update', { message: 'Logging into Google Docs', progress: 0 })

      # Login to HA
      Pusher.trigger('players_channel', 'update', { message: 'Logging into Hockey Arena as speedysportwhiz', progress: 0 })
      @@agent = Mechanize.new
      @@agent.get('http://www.hockeyarena.net/en/')
      form = @@agent.page.forms.first
      form.nick = ENV['HA_nick']
      form.password = ENV['HA_password']
      form.submit

      # Update 17/18yo
      for a in 2..@@ws19.num_rows
        @@player_number += 1
        string = "Updating #{@@ws19[a,1]} (#{@@player_number} of #{@@total_players})"
        Pusher.trigger('players_channel', 'update', { message: string, progress: @@player_number/@@total_players*100.0 })
        begin
          @@agent = update_player(@@ws19, a, @@agent, false)
        rescue Nokogiri::XML::XPath::SyntaxError => e
          puts "**********Happening here in first loop: #{@@ws19[a,1]}**********"
          @@player_number -= 1
          redo
        end
      end
      
      # Update 17/18yo
      for b in 2..@@ws17.num_rows
        unless @@ws17[b,29] == 'y'
          @@player_number += 1
          string = "Updating #{@@ws17[b,1]} (#{@@player_number} of #{@@total_players})"
          Pusher.trigger('players_channel', 'update', { message: string, progress: @@player_number/@@total_players*100.0 })
          begin
            @@agent = update_player(@@ws17, b, @@agent, false)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            puts "**********Happening here in second loop: #{@@ws17[b,1]}**********"
            @@player_number -= 1
            redo
          end
        end
      end
    end

    def update_U20_asst
      # Login as assistant
      Pusher.trigger('players_channel', 'update', { message: 'Logging into Hockey Arena as magicspeedo', progress: @@player_number/@@total_players*100.0 })
      @@agent = Mechanize.new
      @@agent.get('http://www.hockeyarena.net/en/')
      form = @@agent.page.forms.first
      form.nick = ENV['HA_assistant']
      form.password = ENV['HA_password']
      form.submit

      # Update players scouted by assistant
      for b in 2..@@ws17.num_rows
        if @@ws17[b,29] == 'y'
          @@player_number += 1
          string = "Updating #{@@ws17[b,1]} (#{@@player_number} of #{@@total_players})"
          Pusher.trigger('players_channel', 'update', { message: string, progress: @@player_number/@@total_players*100.0 })
          begin
            @@agent = update_player(@@ws17, b, @@agent, true)
          rescue Nokogiri::XML::XPath::SyntaxError => e
            puts "**********Happening here in second loop: #{@@ws17[b,1]}**********"
            @@player_number -= 1
            redo
          end
        end
      end

      Pusher.trigger('players_channel', 'update', { message: '', progress: 0 })
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

    def update_player(ws, i, agent, asst)
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

      agent.page.link_with(:text => player_info[5]).click
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
end