module Api
  module V1
    class SentimentController < BaseController
      def create
        authorize :dashboard, :show?
        text = params[:text].to_s
        return render json: { error: "text is required" }, status: :unprocessable_entity if text.blank?

        result = Ai::SentimentService.new.analyze(text)
        render json: result
      end
    end
  end
end
