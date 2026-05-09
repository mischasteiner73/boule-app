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
    player_ids = players.map(&:id)
    rounds = load_rounds(tournament: tournament, serie: serie)
    stats = compute_player_stats(rounds, player_ids)

    entries = players.map do |player|
      s = stats[player.id]
      wins   = s[:wins]
      total  = s[:rounds]
      points = s[:points]
      {
        player:   player,
        wins:     wins,
        rounds:   total,
        win_pct:  total > 0 ? (wins.to_f / total * 100).round(1) : 0.0,
        points:   points,
        avg_score: total > 0 ? (points.to_f / total).round(1) : 0.0,
        streak:   s[:max_streak],
        margin:   s[:margins].max || 0
      }
    end

    @by_wins           = entries.sort_by { |e| [-e[:wins],      e[:player].name] }
    @by_win_percentage = entries.sort_by { |e| [-e[:win_pct],   e[:player].name] }
    @by_points         = entries.sort_by { |e| [-e[:points],    e[:player].name] }
    @by_average_score  = entries.sort_by { |e| [-e[:avg_score], e[:player].name] }
    @by_streak         = entries.sort_by { |e| [-e[:streak],    e[:player].name] }
    @by_win_margin     = entries.sort_by { |e| [-e[:margin],    e[:player].name] }
    @best_duos         = compute_best_duos(rounds, player_ids)
    @tightest_rounds   = compute_tightest_rounds(rounds)
  end

  def load_rounds(tournament: nil, serie: nil)
    scope = Round.includes(:round_scores, game: { teams: :players })
    scope = scope.joins(:game).where(games: { tournament: tournament }) if tournament
    scope = scope.joins(game: :tournament).where(tournaments: { tournament_serie_id: serie.id }) if serie
    scope.order(:id).to_a
  end

  def compute_player_stats(rounds, player_ids)
    stats = Hash.new do |h, k|
      h[k] = { wins: 0, rounds: 0, points: 0, current_streak: 0, max_streak: 0, margins: [] }
    end

    rounds.each do |round|
      scores    = round.round_scores.to_a
      max_score = scores.map(&:score).compact.max
      next if max_score.nil?

      sorted_scores = scores.map(&:score).compact.sort.reverse
      margin = sorted_scores.size >= 2 ? sorted_scores[0] - sorted_scores[1] : 0

      round.game.teams.each do |team|
        relevant_ids = team.players.map(&:id) & player_ids
        next if relevant_ids.empty?

        team_score = scores.find { |rs| rs.team_id == team.id }&.score
        next if team_score.nil?

        won = team_score == max_score

        relevant_ids.each do |player_id|
          s = stats[player_id]
          s[:rounds] += 1
          s[:points] += team_score
          if won
            s[:wins] += 1
            s[:current_streak] += 1
            s[:max_streak] = [s[:max_streak], s[:current_streak]].max
            s[:margins] << margin
          else
            s[:current_streak] = 0
          end
        end
      end
    end

    stats
  end

  def compute_best_duos(rounds, player_ids)
    duo_stats = Hash.new { |h, k| h[k] = { players: nil, wins: 0, rounds: 0 } }

    rounds.each do |round|
      scores    = round.round_scores.to_a
      max_score = scores.map(&:score).compact.max
      next if max_score.nil?

      round.game.teams.each do |team|
        scoped_players = team.players.select { |p| player_ids.include?(p.id) }
        next if scoped_players.size < 2

        team_score = scores.find { |rs| rs.team_id == team.id }&.score
        next if team_score.nil?

        won = team_score == max_score

        scoped_players.combination(2).each do |pair|
          key = pair.map(&:id).sort
          duo_stats[key][:players] ||= pair.sort_by(&:name)
          duo_stats[key][:rounds] += 1
          duo_stats[key][:wins]   += 1 if won
        end
      end
    end

    duo_stats.values
      .select { |duo| duo[:rounds] >= 1 }
      .sort_by { |duo| [-duo[:wins].to_f / [duo[:rounds], 1].max, duo[:players].map(&:name).join] }
      .first(5)
  end

  def compute_tightest_rounds(rounds)
    rounds.filter_map do |round|
      scores = round.round_scores.map(&:score).compact.sort.reverse
      next if scores.size < 2
      { round: round, margin: scores[0] - scores[1], scores: scores }
    end.sort_by { |e| [e[:margin], -e[:scores][0]] }.first(5)
  end
end
