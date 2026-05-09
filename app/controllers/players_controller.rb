class PlayersController < ApplicationController
  before_action :set_player, only: [:show, :edit, :update, :destroy]

  def index
    @series = TournamentSerie.order(:name)
    @tournaments = Tournament.order(:name)

    @players = if params[:serie_id].present?
      @selected_serie = TournamentSerie.find(params[:serie_id])
      Player.joins(teams: { game: :tournament })
            .where(tournaments: { tournament_serie_id: params[:serie_id] })
            .distinct
            .order(:name)
    elsif params[:tournament_id].present?
      @selected_tournament = Tournament.find(params[:tournament_id])
      Player.joins(teams: :game)
            .where(games: { tournament_id: params[:tournament_id] })
            .distinct
            .order(:name)
    else
      Player.order(:name)
    end
  end

  def show
  end

  def new
    @player = Player.new
  end

  def create
    @player = Player.new(player_params)
    if @player.save
      redirect_to players_path, notice: "Player was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @player.update(player_params)
      redirect_to players_path, notice: "Player was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @player.destroy
    redirect_to players_path, notice: "Player was successfully deleted."
  end

  private

  def set_player
    @player = Player.find(params[:id])
  end

  def player_params
    params.require(:player).permit(:name)
  end
end
