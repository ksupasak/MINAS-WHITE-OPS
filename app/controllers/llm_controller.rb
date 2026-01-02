class LlmController < ApplicationController
  include ActionController::Live
  
  before_action :load_chat_history, except: [:stream]
  before_action :load_search_results, except: [:stream]

  def index
    authorize :dashboard, :show?
    @models = chat_service.list_models
    @current_model = chat_service.current_model
    @notebook = Ai::NotebookService.new
  end

  # Legacy POST endpoint (non-streaming)
  def create
    authorize :dashboard, :show?
    @prompt = params[:prompt].to_s.strip
    
    if @prompt.blank?
      respond_to do |format|
        format.html { redirect_to llm_path, alert: "Message can't be blank" }
        format.json { render json: { error: "Message can't be blank" }, status: :unprocessable_entity }
      end
      return
    end

    # Save user message to database
    save_message(role: "user", content: @prompt)
    
    # Get AI response
    response = chat_service.chat(@messages, system_prompt: system_prompt)
    
    # Save assistant message to database
    save_message(role: "assistant", content: response)

    # Perform search and save results
    @notebook = Ai::NotebookService.new
    search_result = @notebook.query(customer_id: Current.customer.id, question: @prompt, top_k: 10)
    session[:search_results] = {
      query: @prompt,
      answer: search_result[:answer],
      sources: search_result[:sources],
      timestamp: Time.current
    }
    
    respond_to do |format|
      format.html { redirect_to llm_path }
      format.json { render json: { message: response, messages: @messages, search: search_result } }
    end
  end

  # Streaming chat endpoint using Server-Sent Events (SSE)
  def stream
    authorize :dashboard, :show?
    
    prompt = params[:prompt].to_s.strip
    
    if prompt.blank?
      render json: { error: "Message can't be blank" }, status: :unprocessable_entity
      return
    end

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Connection"] = "keep-alive"
    response.headers["X-Accel-Buffering"] = "no"
    
    # Load messages from database
    messages = load_messages_from_db
    
    # Save user message to database
    user_msg = ChatMessage.create!(
      customer_id: Current.customer&.id,
      user_id: current_user&.id,
      session_id: chat_session_id,
      role: "user",
      content: prompt
    )
    
    # Add user message to context
    messages << { role: "user", content: prompt }
    
    # Stream AI response
    full_response = ""
    
    begin
      chat_service.stream_chat(messages, system_prompt: system_prompt) do |chunk|
        full_response = chunk[:full_response] || full_response + chunk[:content]
        
        # Send SSE event
        sse_data = { content: chunk[:content], done: chunk[:done] }.to_json
        response.stream.write("data: #{sse_data}\n\n")
        
        if chunk[:done]
          # Save assistant message to database when done
          ChatMessage.create!(
            customer_id: Current.customer&.id,
            user_id: current_user&.id,
            session_id: chat_session_id,
            role: "assistant",
            content: full_response
          )
          
          # Perform search in background and send as final event
          @notebook = Ai::NotebookService.new
          search_result = @notebook.query(customer_id: Current.customer.id, question: prompt, top_k: 10)
          
          # Send search results as a separate event
          search_data = {
            type: "search",
            query: prompt,
            answer: search_result[:answer],
            sources: search_result[:sources]
          }.to_json
          response.stream.write("data: #{search_data}\n\n")
          
          # Send done signal
          response.stream.write("data: {\"type\":\"complete\"}\n\n")
        end
      end
    rescue IOError, ActionController::Live::ClientDisconnected => e
      Rails.logger.info("Client disconnected: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("Stream error: #{e.message}")
      error_data = { error: e.message }.to_json
      response.stream.write("data: #{error_data}\n\n")
    ensure
      response.stream.close
    end
  end

  def search
    authorize :dashboard, :show?
    @query = params[:query].to_s.strip
    
    if @query.blank?
      respond_to do |format|
        format.html { redirect_to llm_path, alert: "Search query can't be blank" }
        format.json { render json: { error: "Query can't be blank" }, status: :unprocessable_entity }
      end
      return
    end

    @notebook = Ai::NotebookService.new
    search_result = @notebook.query(customer_id: Current.customer.id, question: @query, top_k: 10)
    session[:search_results] = {
      query: @query,
      answer: search_result[:answer],
      sources: search_result[:sources],
      timestamp: Time.current
    }
    
    respond_to do |format|
      format.html { redirect_to llm_path }
      format.json { render json: search_result }
    end
  end

  def clear
    authorize :dashboard, :show?
    
    # Clear messages from database
    ChatMessage.clear_session(chat_session_id)
    
    session[:search_results] = nil
    redirect_to llm_path, notice: "Chat cleared"
  end

  private

  def load_chat_history
    @messages = load_messages_from_db
  end

  def load_messages_from_db
    ChatMessage.for_session(chat_session_id)
               .limit(50)
               .map { |m| { role: m.role, content: m.content, timestamp: m.created_at } }
  end

  def save_message(role:, content:)
    ChatMessage.create!(
      customer_id: Current.customer&.id,
      user_id: current_user&.id,
      session_id: chat_session_id,
      role: role,
      content: content
    )
    
    # Reload messages
    @messages = load_messages_from_db
  end

  def chat_session_id
    # Use a combination of user and customer for unique session
    @chat_session_id ||= begin
      session[:chat_session_id] ||= SecureRandom.uuid
      "#{Current.customer&.id}-#{current_user&.id}-#{session[:chat_session_id]}"
    end
  end

  def load_search_results
    @search_results = session[:search_results] || {}
  end

  def chat_service
    @chat_service ||= Ai::ChatService.new(model: params[:model])
  end

  def system_prompt
    <<~PROMPT
      You are a helpful AI assistant for Social Monitor, a social media analytics platform.
      You help users analyze social media data, understand trends, and provide insights.
      Be concise, helpful, and friendly. Use markdown formatting when appropriate.
    PROMPT
  end
end
