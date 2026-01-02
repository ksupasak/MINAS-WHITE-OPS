class SubjectsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_subject, only: %i[show edit update destroy instant_feed]

  def index
    @subjects = if @project
      policy_scope(@project.subjects).order_by(created_at: :desc)
    else
      policy_scope(Subject).order_by(created_at: :desc)
    end
    authorize Subject
  end

  def show
    authorize @subject
  end

  def new
    @subject = Subject.new(active: true)
    @subject.project = @project if @project
    authorize @subject
  end

  def edit
    authorize @subject
  end

  def create
    @subject = Subject.new(subject_params)
    @subject.project = @project if @project && !subject_params[:project_id]
    @subject.customer ||= Current.customer unless current_user.super_admin?
    authorize @subject

    if @subject.save
      redirect_path = @project ? @project : @subject
      redirect_to redirect_path, notice: "Subject created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @subject
    if @subject.update(subject_params)
      redirect_to @subject, notice: "Subject updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @subject
    project = @subject.project
    @subject.destroy
    redirect_to project || subjects_path, notice: "Subject deleted"
  end

  def destroy_all
    authorize Subject, :destroy_all?
    policy_scope(Subject).destroy_all
    redirect_to subjects_path, notice: "All subjects deleted"
  end

  def instant_feed
    authorize @subject
    
    query = params[:query].presence || @subject.query
    channel = params[:channel]
    region = params[:region] || "th"
    start_index = params[:start_index].to_i
    stop_index = params[:stop_index].to_i
    
    if channel.blank?
      redirect_to @subject, alert: "Please select a channel"
      return
    end

    if stop_index <= start_index
      redirect_to @subject, alert: "Stop index must be greater than start index"
      return
    end

    feeder = Feeder.first
    for i in start_index...stop_index 
    RunFeederJob.perform_async(
      feeder.id.to_s,
      @subject.id.to_s,
      channel,
      region,
        i
      )
    end
    
    redirect_to @subject, notice: "Instant feed job submitted for #{channel} (#{start_index}-#{stop_index})"
  end

  private

  def set_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  end

  def set_subject
    @subject = Subject.find(params[:id])
  end

  def subject_params
    params.require(:subject).permit(:name, :query, :language, :country, :active, :project_id, :customer_id)
  end
end
