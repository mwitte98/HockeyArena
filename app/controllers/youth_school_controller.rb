class YouthSchoolController < ApplicationController
	before_action :signed_in_user
	
	def speedyLiveYS
	  @players = YouthSchool.where(manager: "speedysportwhiz", version: "live", draft: false).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	def speedyLiveDraft
	  @players = YouthSchool.where(manager: "speedysportwhiz", version: "live", draft: true).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	def speedyBetaYS
	  @players = YouthSchool.where(manager: "speedysportwhiz", version: "beta", draft: false).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	def speedyBetaDraft
	  @players = YouthSchool.where(manager: "speedysportwhiz", version: "beta", draft: true).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	def speedoLiveYS
	  @players = YouthSchool.where(manager: "magicspeedo", version: "live", draft: false).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	def speedoLiveDraft
	  @players = YouthSchool.where(manager: "magicspeedo", version: "live", draft: true).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	def speedoBetaYS
	  @players = YouthSchool.where(manager: "magicspeedo", version: "beta", draft: false).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	def speedoBetaDraft
	  @players = YouthSchool.where(manager: "magicspeedo", version: "beta", draft: true).order("priority ASC")
	  @dates, @ai_array, @calculations = prepare_tables(@players)
	end
	
	private

      def signed_in_user
        unless signed_in?
          flash[:warning] = "You must be signed in to access that page."
          redirect_to root_url
        end
      end
	  
	  def prepare_tables(players)
		if players.empty?
		  return [], [], []
		end
	    @dates = []
		players.last.ai.keys.sort.each do |key|
		  time = key.to_time.getgm + 1.days
	      @dates << "#{time.day}.#{time.month}"
		end
		@ai_array = []
		@calculations = []
		player_ai = []
		player_calculations = []
		players.each do |player|
	      player.ai.keys.sort.each do |key|
		    player_ai << player.ai[key].to_i
		  end
		  @ai_array << player_ai
		  length = player_ai.length
		  player_calculations << player_ai.inject(:+).to_f / length #average
		  player_calculations << player_ai.min #min
		  sorted = player_ai.sort
		  player_calculations << (sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0 #median
		  player_calculations << player_ai.max #max
		  player_calculations << 0 #times above ai for age
		  player_ai.each do |ai|
		    if (player.age == 16 and ai >= 40) or (player.age == 17 and ai >= 70) or (player.age == 18 and ai >= 100)
		      player_calculations[4] += 1
		    end
		  end
		  @calculations << player_calculations
		  player_ai = []
		  player_calculations = []
		end
		return @dates, @ai_array, @calculations
	  end
end