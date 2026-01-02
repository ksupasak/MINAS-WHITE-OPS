module Api
  module V1
    class GraphController < BaseController
      def index
        authorize :dashboard, :show?
        subject_id = params[:subject_id]
        from_time = parse_time(params[:from])
        to_time = parse_time(params[:to])

        service = Graph::Queries.new(customer: Current.customer)
        data = service.subject_graph(subject_id: subject_id, from: from_time, to: to_time)
        render json: data
      end

      private

      def parse_time(value)
        return nil unless value.present?
        Time.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
