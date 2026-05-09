class Player < ApplicationRecord
  has_many :team_players, dependent: :destroy
  has_many :teams, through: :team_players

  validates :name, presence: true, uniqueness: true

  def all_games(tournament: nil)
    scope = Game.joins(teams: :team_players).where(team_players: { player_id: id }).distinct.order(played_at: :desc)
    scope = scope.where(tournament: tournament) if tournament
    scope
  end

  def all_rounds(tournament: nil)
    scope = Round.joins(game: { teams: :team_players }).where(team_players: { player_id: id }).distinct
    scope = scope.where(games: { tournament_id: tournament.id }) if tournament
    scope
  end

  def wins(tournament: nil)
    all_rounds(tournament: tournament).count { |round| won_round?(round) }
  end

  def total_rounds(tournament: nil)
    all_rounds(tournament: tournament).count
  end

  def win_percentage(tournament: nil)
    rounds = total_rounds(tournament: tournament)
    return 0.0 if rounds.zero?
    (wins(tournament: tournament).to_f / rounds * 100).round(1)
  end

  def total_points(tournament: nil)
    scope = RoundScore.joins(team: :team_players).where(team_players: { player_id: id })
    scope = scope.joins(round: :game).where(games: { tournament_id: tournament.id }) if tournament
    scope.sum(:score)
  end

  def average_score(tournament: nil)
    rounds = total_rounds(tournament: tournament)
    return 0.0 if rounds.zero?
    (total_points(tournament: tournament).to_f / rounds).round(1)
  end

  def longest_winning_streak(tournament: nil)
    streak = 0
    max_streak = 0
    all_rounds(tournament: tournament).order(:id).each do |round|
      if won_round?(round)
        streak += 1
        max_streak = [max_streak, streak].max
      else
        streak = 0
      end
    end
    max_streak
  end

  def biggest_win_margin(tournament: nil)
    all_rounds(tournament: tournament).order(:id).filter_map do |round|
      next unless won_round?(round)
      scores = round.round_scores.map(&:score).compact.sort.reverse
      next if scores.size < 2
      scores[0] - scores[1]
    end.max || 0
  end

  def won_round?(round)
    max_score = round.round_scores.maximum(:score)
    return false if max_score.nil?
    player_team_ids = teams.where(game: round.game).pluck(:id)
    round.round_scores.where(team_id: player_team_ids).any? { |rs| rs.score == max_score }
  end
end
