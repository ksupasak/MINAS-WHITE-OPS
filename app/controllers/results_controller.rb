class ResultsController < ApplicationController

  before_action :set_result, only: %i[show   destroy]

  def index
    @results = policy_scope(Result).order_by(created_at: :desc)
    authorize Result
  end

  def show
    authorize @result
  end

  def upsert
    authorize @result
    @result.upsert
    redirect_to result_path(@result), notice: "Result upserted"
  end

  def destroy
    authorize @result
    @result.destroy
    redirect_to results_path, notice: "Result deleted"
  end

  def destroy_all
    authorize Result, :destroy_all?
    policy_scope(Result).delete_all
    redirect_to results_path, notice: "All results deleted"
  end

  private

  def set_result
    @result = Result.find(params[:id])
  end
end
