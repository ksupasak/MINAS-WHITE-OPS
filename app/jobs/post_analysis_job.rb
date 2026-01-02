class PostAnalysisJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    
    post = Post.find(post_id)

    post.analyze_sentiment
    post.index_post

  rescue Mongoid::Errors::DocumentNotFound
    Rails.logger.warn "PostAnalysisJob: Post #{post_id} not found"
  end
end
