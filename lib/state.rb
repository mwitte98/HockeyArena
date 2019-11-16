module State
  class << State
    attr_accessor :sheet, :team, :row, :manager, :version, :is_draft, :ab_team

    def update_row?(row_num)
      @row = row_num
      is_b_sheet = @sheet[@row, 31].downcase == 'b'
      is_b_team = @ab_team == 'b'
      is_y = @sheet[@row, 30] == 'y'
      is_senior_team = @team == 'senior'

      update_row_for_state? is_b_sheet, is_b_team, is_y, is_senior_team
    end

    private

    def update_row_for_state?(is_b_sheet, is_b_team, is_y, is_senior_team)
      if @sheet[@row, 28] == ''
        false
      elsif is_b_sheet != is_b_team
        false
      elsif @manager == 'speedysportwhiz'
        is_senior_team == is_y
      else
        is_senior_team != is_y
      end
    end
  end
end
