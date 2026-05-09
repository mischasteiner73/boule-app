class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy, :setup_teams, :save_teams]

  def index
    @games = Game.includes(:tournament, teams: :players, rounds: :round_scores).order(played_at: :desc)
  end

  def show
    @teams  = @game.teams.includes(:players).to_a
    @rounds = @game.rounds.includes(round_scores: :team).order(:id).to_a

    @team_wins = @teams.each_with_object(Hash.new(0)) do |team, counts|
      @rounds.each do |round|
        max = round.round_scores.map(&:score).compact.max
        rs  = round.round_scores.find { |s| s.team_id == team.id }
        counts[team.id] += 1 if rs&.score == max
      end
    end

    @team_totals = @teams.each_with_object({}) do |team, totals|
      totals[team.id] = @rounds.sum do |round|
        round.round_scores.find { |s| s.team_id == team.id }&.score.to_i
      end
    end
  end

  def new
    @game = Game.new(played_at: Time.current)
    @tournaments = Tournament.order(:name)
  end

  def create
    @game = Game.new(game_params)
    if @game.save
      redirect_to setup_teams_game_path(@game), notice: "Game created. Now set up the teams."
    else
      @tournaments = Tournament.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @game.update(game_params)
      redirect_to game_path(@game), notice: "Game was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @game.destroy
    redirect_to games_path, notice: "Game was successfully deleted."
  end

  def setup_teams
    @players = Player.order(:name)
    @team_count = @game.teams.count > 0 ? @game.teams.count : 2
  end

  def save_teams
    team_players_params = params[:teams]

    unless team_players_params.present?
      redirect_to setup_teams_game_path(@game), alert: "Please assign players to teams."
      return
    end

    ActiveRecord::Base.transaction do
      @game.teams.destroy_all

      team_players_params.each_value do |team_data|
        player_ids = Array(team_data[:player_ids]).reject(&:blank?)
        next if player_ids.empty?

        team = @game.teams.create!
        player_ids.each { |player_id| team.team_players.create!(player_id: player_id) }
      end
    end

    redirect_to game_path(@game), notice: "Teams and scores saved."
  rescue ActiveRecord::RecordInvalid => exception
    @players = Player.order(:name)
    @team_count = params[:teams]&.length || 2
    flash.now[:alert] = exception.message
    render :setup_teams, status: :unprocessable_entity
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:played_at, :tournament_id)
  end
end
