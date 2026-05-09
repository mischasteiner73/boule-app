class TournamentsController < ApplicationController
  before_action :set_tournament, only: [:edit, :update, :destroy]
  before_action :set_series, only: [:new, :create, :edit, :update]

  def index
    @tournaments = Tournament.order(:name).includes(:tournament_serie, games: :rounds)
  end

  def new
    @tournament = Tournament.new
  end

  def create
    @tournament = Tournament.new(tournament_params)
    if @tournament.save
      redirect_to tournaments_path, notice: "Tournament was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tournament.update(tournament_params)
      redirect_to tournaments_path, notice: "Tournament was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @tournament.destroy
      redirect_to tournaments_path, notice: "Tournament was successfully deleted."
    else
      redirect_to tournaments_path, alert: @tournament.errors.full_messages.to_sentence
    end
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(:name, :tournament_serie_id)
  end

  def set_series
    @series = TournamentSerie.order(:name)
  end
end
