class ModelsController < ApplicationController
  before_action :set_model, only: %i[show edit update destroy]

  def index
    @models = policy_scope(Model).order_by(created_at: :desc)
    authorize Model
  end

  def show
    authorize @model
  end

  def new
    @model = Model.new
    authorize @model
  end

  def edit
    authorize @model
  end

  def create
    @model = Model.new(model_params)
    authorize @model

    if @model.save
      redirect_to @model, notice: "Model created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @model
    if @model.update(model_params)
      redirect_to @model, notice: "Model updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @model
    @model.destroy
    redirect_to models_path, notice: "Model deleted"
  end

  def destroy_all
    authorize Model, :destroy_all?
    policy_scope(Model).destroy_all
    redirect_to models_path, notice: "All models deleted"
  end

  private

  def set_model
    @model = Model.find(params[:id])
  end

  def model_params
    params.require(:model).permit(:name, :provider, :model_id, :version, :host, :token, :active, :description, capabilities: [])
  end
end
