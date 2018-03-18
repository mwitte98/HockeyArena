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
    @agent = Mechanize.new
    login_to_ha

    page = @agent.page
    if page.content.include?('Continue')
      puts "*****Login #{login_attempt} to HA failed for #{manager} #{version}*****"
      page.search('#page').each { |info| puts info.text }
      return
    end

    run_updates
  end

  def run_updates
    if version == 'live'
      UpdateNT.run @ws_u20_active, ENV['U20_20_seasons']
      UpdateNT.run @ws_u20_next, ENV['U20_18_seasons']
      UpdateNT.run @ws_sr, 'senior'
    end
    UpdateYS.run false # update ys
    UpdateYS.run true # update draft
  end

  def login_to_ha
    is_version_live = State.version == 'live'
    @agent.get(is_version_live ? 'http://www.hockeyarena.net/en/' : 'http://beta.hockeyarena.net/en/')
    form = @agent.page.forms.first
    form.nick = State.manager
    form.password = is_version_live ? ENV['HA_password'] : ENV['beta_password']
    form.submit
    sleep 1
  end

  def get_first_worksheet(session, key)
    session.spreadsheet_by_key(key).worksheets[0]
  end
end
