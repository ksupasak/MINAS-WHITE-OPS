module Api
  module V1
    class NotebookController < BaseController
      def query
        authorize :dashboard, :show?
        question = params[:question].to_s
        top_k = params[:top_k].presence&.to_i || 5

        if question.blank?
          return render json: { error: "question is required" }, status: :unprocessable_entity
        end

        service = Ai::NotebookService.new
        result = service.query(customer_id: Current.customer.id, question: question, top_k: top_k)
        render json: result
      end
    end
  end
end
