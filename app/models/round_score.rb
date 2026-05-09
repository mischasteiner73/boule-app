class RoundScore < ApplicationRecord
  belongs_to :round
  belongs_to :team

  validates :score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
