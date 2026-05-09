class StatisticsController < ApplicationController
  def index
    @tournament = nil
    @serie = nil
    @tournaments = Tournament.order(:name)
    @series = TournamentSerie.order(:name)
    setup_stats(Player.all.to_a)
  end

  def tournament
    @tournament = Tournament.find(params[:id])
    @serie = nil
    @tournaments = Tournament.order(:name)
    @series = TournamentSerie.order(:name)
    players = Player.joins(teams: :game).where(games: { tournament: @tournament }).distinct.to_a
    setup_stats(players, tournament: @tournament)
  end

  def serie
    @serie = TournamentSerie.find(params[:id])
    @tournament = nil
    @tournaments = Tournament.order(:name)
    @series = TournamentSerie.order(:name)
    players = Player.joins(teams: { game: :tournament })
                    .where(tournaments: { tournament_serie_id: @serie.id })
                    .distinct.to_a
    setup_stats(players, serie: @serie)
  end

  private

  def setup_stats(players, tournament: nil, serie: nil)
    opts = { tournament: tournament, serie: serie }
    @by_wins           = players.sort_by { |p| [-p.wins(**opts), p.name] }
    @by_win_percentage = players.sort_by { |p| [-p.win_percentage(**opts), p.name] }
    @by_points         = players.sort_by { |p| [-p.total_points(**opts), p.name] }
    @by_average_score  = players.sort_by { |p| [-p.average_score(**opts), p.name] }
    @by_streak         = players.sort_by { |p| [-p.longest_winning_streak(**opts), p.name] }
    @by_win_margin     = players.sort_by { |p| [-p.biggest_win_margin(**opts), p.name] }
    @best_duos         = compute_best_duos(**opts)
    @tightest_rounds   = compute_tightest_rounds(**opts)
  end

  def compute_best_duos(tournament: nil, serie: nil)
    duo_stats = Hash.new { |hash, key| hash[key] = { players: nil, wins: 0, rounds: 0 } }

    scope = Team.includes(:players, round_scores: { round: :round_scores })
    scope = scope.joins(:game).where(games: { tournament: tournament }) if tournament
    scope = scope.joins(game: :tournament).where(tournaments: { tournament_serie_id: serie.id }) if serie

    scope.each do |team|
      players = team.players.to_a
      next if players.size < 2

      players.combination(2).each do |pair|
        key = pair.map(&:id).sort
        duo_stats[key][:players] ||= pair.sort_by(&:name)

        team.round_scores.each do |rs|
          duo_stats[key][:rounds] += 1
          max_score = rs.round.round_scores.map(&:score).compact.max
          duo_stats[key][:wins] += 1 if rs.score == max_score
        end
      end
    end

    duo_stats.values
      .select { |duo| duo[:rounds] >= 1 }
      .sort_by { |duo| [-duo[:wins].to_f / [duo[:rounds], 1].max, duo[:players].map(&:name).join] }
      .first(5)
  end

  def compute_tightest_rounds(tournament: nil, serie: nil)
    scope = Round.includes(:round_scores, game: { teams: :players })
    scope = scope.joins(:game).where(games: { tournament: tournament }) if tournament
    scope = scope.joins(game: :tournament).where(tournaments: { tournament_serie_id: serie.id }) if serie

    scope.map do |round|
      scores = round.round_scores.map(&:score).compact.sort.reverse
      next if scores.size < 2
      margin = scores[0] - scores[1]
      { round: round, margin: margin, scores: scores }
    end.compact.sort_by { |entry| [entry[:margin], -entry[:scores][0]] }.first(5)
  end
end
