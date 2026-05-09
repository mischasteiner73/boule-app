class Team < ApplicationRecord
  belongs_to :game
  has_many :team_players, dependent: :destroy
  has_many :players, through: :team_players
  has_many :round_scores, dependent: :destroy
end
