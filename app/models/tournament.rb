class Tournament < ApplicationRecord
  belongs_to :tournament_serie
  has_many :games, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
