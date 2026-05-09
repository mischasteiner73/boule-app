class AddTournamentToGames < ActiveRecord::Migration[8.1]
  class Tournament < ApplicationRecord; end

  def up
    add_column :games, :tournament_id, :integer

    tournament = Tournament.create!(name: "Auressio 2026")
    execute("UPDATE games SET tournament_id = #{tournament.id}")

    change_column_null :games, :tournament_id, false
    add_foreign_key :games, :tournaments
    add_index :games, :tournament_id
  end

  def down
    remove_foreign_key :games, :tournaments
    remove_index :games, :tournament_id
    remove_column :games, :tournament_id
  end
end
