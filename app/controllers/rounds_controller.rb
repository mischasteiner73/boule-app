class RoundsController < ApplicationController
  before_action :set_game

  def create
    round = @game.rounds.build

    ActiveRecord::Base.transaction do
      round.save!
      @game.teams.each do |team|
        score = params.dig(:scores, team.id.to_s).presence
        round.round_scores.create!(team: team, score: score)
      end
    end

    redirect_to game_path(@game), notice: "Round #{@game.rounds.count} added."
  rescue ActiveRecord::RecordInvalid => exception
    redirect_to game_path(@game), alert: exception.message
  end

  def destroy
    round = @game.rounds.find(params[:id])
    round.destroy
    redirect_to game_path(@game), notice: "Round deleted."
  end

  private

  def set_game
    @game = Game.find(params[:game_id])
  end
end
