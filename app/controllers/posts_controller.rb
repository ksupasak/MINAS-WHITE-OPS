class PostsController < ApplicationController
  before_action :set_post, only: %i[show edit update destroy index_post analyze_sentiment]

  def index
    @posts = policy_scope(Post).order_by(created_at: :desc).limit(100)
    authorize Post
  end

  def show
    authorize @post
  end

  def new
    @post = Post.new
    authorize @post
  end

  def edit
    authorize @post
  end

  def create
    @post = Post.new(post_params)
    authorize @post

    if @post.save
      redirect_to @post, notice: "Post created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @post
    if @post.update(post_params)
      redirect_to @post, notice: "Post updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post
    @post.destroy
    redirect_to posts_path, notice: "Post deleted"
  end

  def destroy_all
    authorize Post, :destroy_all?
    policy_scope(Post).destroy_all
    redirect_to posts_path, notice: "All posts deleted"
  end

  def index_post
    authorize @post
    
    @post.index_post

    redirect_to @post, notice: "Post indexed"
  end

  def analyze_sentiment

    authorize @post

    @post.analyze_sentiment

    redirect_to @post, notice: "Sentiment analyzed"

  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:post_id, :channel, :title, :link, :text, :snippet, :source, :hashtags)
  end
end
