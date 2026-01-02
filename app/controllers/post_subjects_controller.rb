class PostSubjectsController < ApplicationController
  before_action :set_post_subject, only: %i[show edit update destroy]

  def index
    @post_subjects = policy_scope(PostSubject).order_by(created_at: :desc).limit(100)
    authorize PostSubject
  end

  def show
    authorize @post_subject
  end

  def new
    @post_subject = PostSubject.new
    authorize @post_subject
  end

  def edit
    authorize @post_subject
  end

  def create
    @post_subject = PostSubject.new(post_subject_params)
    authorize @post_subject

    if @post_subject.save
      redirect_to @post_subject, notice: "Post subject created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @post_subject
    if @post_subject.update(post_subject_params)
      redirect_to @post_subject, notice: "Post subject updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post_subject
    @post_subject.destroy
    redirect_to post_subjects_path, notice: "Post subject deleted"
  end

  def destroy_all
    authorize PostSubject, :destroy_all?
    policy_scope(PostSubject).destroy_all
    redirect_to post_subjects_path, notice: "All post subjects deleted"
  end

  private

  def set_post_subject
    @post_subject = PostSubject.find(params[:id])
  end

  def post_subject_params
    params.require(:post_subject).permit(:post_id, :subject_id, :sentiment, :model_id, :note, :confidence, :analyzed_at)
  end
end
