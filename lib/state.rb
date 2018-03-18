module State
  class << State
    attr_accessor :sheet, :team, :row, :manager, :version, :is_draft

    def update_row?(row_num)
      @row = row_num
      if @sheet[row, 28] == ''
        false
      elsif @manager == 'speedysportwhiz'
        update_row_for_speedy?
      else
        update_row_for_speedo?
      end
    end

    private

    def update_row_for_speedy?
      is_y = @sheet[@row, 30] == 'y'
      is_senior_team = @team == 'senior'
      (!is_senior_team && !is_y) || (is_senior_team && is_y)
    end

    def update_row_for_speedo?
      is_y = @sheet[@row, 30] == 'y'
      is_senior_team = @team == 'senior'
      (!is_senior_team && is_y) || (is_senior_team && !is_y)
    end
  end
end
