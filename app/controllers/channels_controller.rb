class ChannelsController < ApplicationController
  before_action :set_channel, only: %i[show edit update destroy]

  def index
    @channels = policy_scope(Channel).order_by(created_at: :desc)
    authorize Channel
  end

  def show
    authorize @channel
  end

  def new
    @channel = Channel.new
    authorize @channel
  end

  def edit
    authorize @channel
  end

  def create
    @channel = Channel.new(channel_params)
    authorize @channel

    if @channel.save
      redirect_to @channel, notice: "Channel created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @channel
    if @channel.update(channel_params)
      redirect_to @channel, notice: "Channel updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @channel
    @channel.destroy
    redirect_to channels_path, notice: "Channel deleted"
  end

  def destroy_all
    authorize Channel, :destroy_all?
    policy_scope(Channel).destroy_all
    redirect_to channels_path, notice: "All channels deleted"
  end

  private

  def set_channel
    @channel = Channel.find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(:name)
  end
end
