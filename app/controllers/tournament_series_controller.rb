class TournamentSeriesController < ApplicationController
  before_action :set_serie, only: [:edit, :update, :destroy]

  def index
    @series = TournamentSerie.order(:name).includes(tournaments: { games: :rounds })
  end

  def new
    @serie = TournamentSerie.new
    @tournaments = Tournament.order(:name)
  end

  def create
    @serie = TournamentSerie.new(serie_params)
    if @serie.save
      assign_tournaments(@serie)
      redirect_to tournament_series_index_path, notice: "Series was successfully created."
    else
      @tournaments = Tournament.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @tournaments = Tournament.order(:name)
  end

  def update
    if @serie.update(serie_params)
      assign_tournaments(@serie)
      redirect_to tournament_series_index_path, notice: "Series was successfully updated."
    else
      @tournaments = Tournament.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @serie.destroy
      redirect_to tournament_series_index_path, notice: "Series was successfully deleted."
    else
      redirect_to tournament_series_index_path, alert: @serie.errors.full_messages.to_sentence
    end
  end

  private

  def set_serie
    @serie = TournamentSerie.find(params[:id])
  end

  def serie_params
    params.require(:tournament_serie).permit(:name)
  end

  def assign_tournaments(serie)
    selected_ids = Array(params.dig(:tournament_serie, :tournament_ids)).reject(&:blank?).map(&:to_i)
    Tournament.where(tournament_serie: serie).where.not(id: selected_ids).update_all(tournament_serie_id: nil)
    Tournament.where(id: selected_ids).update_all(tournament_serie_id: serie.id)
  end
end
