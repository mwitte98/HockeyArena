class UpdateJob
  include SuckerPunch::Job

  def initialize
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(ENV['client_secret']))
    @ws_u20_active = get_first_worksheet session, ENV['U20_20_key']
    @ws_u20_next = get_first_worksheet session, ENV['U20_18_key']
    @ws_sr = get_first_worksheet session, ENV['NT_key']
  end

  def perform
    update 'speedysportwhiz', 'live'
    update 'magicspeedo', 'live'
    update 'speedysportwhiz', 'beta'
    update 'magicspeedo', 'beta'
  end

  private

  def update(manager, version)
    State.manager = manager
    State.version = version
    go_to_homepage
    login_to_ha
    return if login_failed?
    run_updates
  end

  def go_to_homepage
    @agent = Mechanize.new
    if State.version == 'live'
      @agent.get('http://www.hockeyarena.net/en/')
    else
      @agent.get('http://beta.hockeyarena.net/en/')
    end
  end

  def login_to_ha
    form = @agent.page.forms.first
    form.nick = State.manager
    form.password = State.version == 'live' ? ENV['HA_password'] : ENV['beta_password']
    form.submit
  end

  def login_failed?
    sleep 1
    content = @agent.page.content
    if content.include?('Continue')
      puts "*****Login to HA failed for #{State.manager} #{State.version}*****"
      puts content
      return true
    end
    false
  end

  def run_updates
    if State.version == 'live'
      UpdateNT.run @agent, @ws_u20_active, ENV['U20_20_seasons']
      UpdateNT.run @agent, @ws_u20_next, ENV['U20_18_seasons']
      UpdateNT.run @agent, @ws_sr, 'senior'
    end
    UpdateYS.run @agent, false # update ys
    UpdateYS.run @agent, true # update draft
  end

  def get_first_worksheet(session, key)
    session.spreadsheet_by_key(key).worksheets[0]
  end
end
