class CreateRoundScores < ActiveRecord::Migration[8.1]
  def change
    create_table :round_scores do |t|
      t.references :round, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :score

      t.timestamps
    end
  end
end
