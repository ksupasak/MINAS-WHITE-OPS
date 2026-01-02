module Api
  module V1
    class AnalyticsController < BaseController
      def top_hashtags
        authorize :dashboard, :show?
        data = query_service.top_hashtags(subject_id: params[:subject_id])
        render json: data
      end

      def top_users
        authorize :dashboard, :show?
        data = query_service.top_users(subject_id: params[:subject_id])
        render json: data
      end

      private

      def query_service
        Graph::Queries.new(customer: Current.customer)
      end
    end
  end
end
