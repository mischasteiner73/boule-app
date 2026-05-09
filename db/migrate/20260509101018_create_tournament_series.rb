class CreateTournamentSeries < ActiveRecord::Migration[8.1]
  def up
    create_table :tournament_series do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :tournament_series, :name, unique: true

    add_column :tournaments, :tournament_serie_id, :bigint
    add_foreign_key :tournaments, :tournament_series, column: :tournament_serie_id

    result = execute("INSERT INTO tournament_series (name, created_at, updated_at) VALUES ('Alpenboule Auressio', NOW(), NOW()) RETURNING id")
    serie_id = result.first["id"]
    execute("UPDATE tournaments SET tournament_serie_id = #{serie_id}")
  end

  def down
    remove_foreign_key :tournaments, :tournament_series
    remove_column :tournaments, :tournament_serie_id
    drop_table :tournament_series
  end
end
