class RemoveScoreFromTeams < ActiveRecord::Migration[8.1]
  def change
    remove_column :teams, :score, :integer
  end
end
