class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :score

      t.timestamps
    end
  end
end
