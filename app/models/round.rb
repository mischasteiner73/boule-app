class Round < ApplicationRecord
  belongs_to :game
  has_many :round_scores, dependent: :destroy

  def winner
    round_scores.order(score: :desc).first&.team
  end

  def winning_score
    round_scores.maximum(:score)
  end
end
