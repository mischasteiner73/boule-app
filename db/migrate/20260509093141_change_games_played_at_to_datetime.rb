class ChangeGamesPlayedAtToDatetime < ActiveRecord::Migration[8.1]
  def up
    add_column :games, :played_at_new, :datetime

    execute("UPDATE games SET played_at_new = created_at")

    remove_column :games, :played_at
    rename_column :games, :played_at_new, :played_at
  end

  def down
    add_column :games, :played_at_old, :date

    execute("UPDATE games SET played_at_old = DATE(played_at)")

    remove_column :games, :played_at
    rename_column :games, :played_at_old, :played_at
  end
end
