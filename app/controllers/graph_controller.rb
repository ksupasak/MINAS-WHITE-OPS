class GraphController < ApplicationController
  def show
    authorize :dashboard, :show?
    @subjects = policy_scope(Subject)
    @selected_subject_id = params[:subject_id] || @subjects.first&.id&.to_s
    @from = params[:from]
    @to = params[:to]
  end

  def reprocess
      client = Graph::Client.session(database: @database)
      client.write_transaction do |tx|
        tx.run("MATCH (n) DETACH DELETE n")
      end
      client.close
      redirect_to graph_path, notice: "Reprocessed"
  end
end
