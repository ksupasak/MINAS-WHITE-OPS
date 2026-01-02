class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy analyze_all_sentiment]

  def index
    @projects = policy_scope(Project).order_by(created_at: :desc)
    authorize Project
  end

  def show
    authorize @project
  end

  def new
    @project = Project.new(customer: Current.customer)
    authorize @project
  end

  def edit
    authorize @project
  end

  def create
    @project = Project.new(project_params)
    @project.customer ||= Current.customer unless current_user.super_admin?
    authorize @project

    if @project.save
      redirect_to @project, notice: "Project created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @project
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    @project.destroy
    redirect_to projects_path, notice: "Project deleted"
  end

  def destroy_all
    authorize Project, :destroy_all?
    policy_scope(Project).destroy_all
    redirect_to projects_path, notice: "All projects deleted"
  end

  def analyze_all_sentiment
    authorize @project, :update?
    posts = Post.where(project_id: @project.id)
    posts.each do |post|
      PostAnalysisJob.perform_later(post.id.to_s)
    end
    redirect_to @project, notice: "Queued #{posts.count} posts for sentiment analysis"
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    permitted = %i[name description status sentiment_prompt]
    permitted << :customer_id if current_user.super_admin?
    params.require(:project).permit(permitted)
  end
  
end
