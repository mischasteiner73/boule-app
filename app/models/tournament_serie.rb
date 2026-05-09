class TournamentSerie < ApplicationRecord
  has_many :tournaments, foreign_key: :tournament_serie_id, dependent: :nullify
  has_many :games, through: :tournaments

  validates :name, presence: true, uniqueness: true
end
