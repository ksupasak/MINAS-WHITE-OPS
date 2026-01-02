class SourcesController < ApplicationController
  before_action :set_source, only: %i[show edit update destroy]

  def index
    @sources = policy_scope(Source).order_by(created_at: :desc)
    authorize Source
  end

  def show
    authorize @source
  end

  def new
    @source = Source.new
    authorize @source
  end

  def edit
    authorize @source
  end

  def create
    @source = Source.new(source_params)
    authorize @source

    if @source.save
      redirect_to @source, notice: "Source created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @source
    if @source.update(source_params)
      redirect_to @source, notice: "Source updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @source
    @source.destroy
    redirect_to sources_path, notice: "Source deleted"
  end

  def destroy_all
    authorize Source, :destroy_all?
    policy_scope(Source).destroy_all
    redirect_to sources_path, notice: "All sources deleted"
  end

  private

  def set_source
    @source = Source.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:name, :source_id, :channel, :channel_id)
  end
end
