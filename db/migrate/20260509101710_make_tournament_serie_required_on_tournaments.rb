class MakeTournamentSerieRequiredOnTournaments < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tournaments, :tournament_serie_id, false
  end
end
