class Game < ApplicationRecord
  belongs_to :tournament
  has_many :teams, dependent: :destroy
  has_many :rounds, dependent: :destroy

  validates :played_at, presence: true
end
