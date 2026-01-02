class DashboardController < ApplicationController
  def show
    authorize :dashboard, :show?

    result_scope = current_user&.super_admin? ? Result.all : Result.where(customer_id: Current.customer&.id)
    subject_scope = current_user&.super_admin? ? Subject.all : Subject.where(customer_id: Current.customer&.id)

    @posts_today = result_scope.where(:created_at.gte => Time.zone.today).sum(:posts_count)
    @active_subjects = subject_scope.where(active: true).count
    @feeders = policy_scope(Feeder).limit(5)
    @latest_results = policy_scope(Result).order_by(created_at: :desc).limit(5)
  end

  def status
    authorize :dashboard, :show?

    @redis_status = check_redis
    @mongo_status = check_mongo
    @neo4j_status = check_neo4j
    @tigergraph_status = check_tigergraph
    @ollama_status = check_ollama
    @webui_status = check_webui
    @qdrant_status = check_qdrant
  end

  private

  def check_redis
    redis_url = ENV.fetch("REDIS_URL", "redis://redis:6379/0")
    redis = Redis.new(url: redis_url)
    info = redis.info("server")
    {
      connected: true,
      info: "Connected to #{redis_url}",
      version: info["redis_version"],
      uptime: "#{info["uptime_in_days"]} days"
    }
  rescue => e
    { connected: false, info: e.message }
  ensure
    redis&.close rescue nil
  end

  def check_mongo
    client = Mongoid.default_client
    mongo_uri = client.cluster.addresses.map(&:to_s).join(", ")
    result = client.database.command(ping: 1)
    db_names = client.database_names.first(5).join(", ")
    {
      connected: true,
      info: "Connected to #{mongo_uri}",
      database: client.database.name,
      databases: db_names
    }
  rescue => e
    { connected: false, info: e.message }
  end

  def check_neo4j
    neo4j_uri = Graph::Client.uri
    session = Graph::Client.session
    result = session.run("CALL dbms.components() YIELD name, versions RETURN name, versions[0] as version")
    record = result.first
    session.close if session.respond_to?(:close)
    {
      connected: true,
      info: "Connected to #{neo4j_uri}",
      version: record ? "#{record['name']} #{record['version']}" : "Unknown"
    }
  rescue => e
    { connected: false, info: e.message }
  end

  def check_tigergraph
    host = ENV.fetch("TIGERGRAPH_HOST", nil)
    graph = ENV.fetch("TIGERGRAPH_GRAPH", nil)
    secret = ENV.fetch("TIGERGRAPH_SECRET", nil)

    return { connected: false, info: "Not configured (missing env vars)" } unless host && secret

    client = Graph::TigerGraphClient.new(host: host, graph: graph, secret: secret)
    # Try to get a token to verify connection
    uri = URI.parse(File.join(host, "/api/ping"))
    response = Net::HTTP.get_response(uri)

    {
      connected: true,
      info: "Connected to #{host}",
      graph: graph
    }
  rescue => e
    { connected: false, info: e.message }
  end

  def check_ollama
    host = ENV.fetch("OLLAMA_HOST", "http://ollama:11434")
    uri = URI.parse("#{host}/api/version")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 5
    
    response = http.get(uri.path)
    
    if response.is_a?(Net::HTTPSuccess)
      body = JSON.parse(response.body) rescue {}
      {
        connected: true,
        info: "Connected to #{host}",
        version: body["version"] || "Unknown"
      }
    else
      { connected: false, info: "HTTP #{response.code}" }
    end
  rescue => e
    { connected: false, info: e.message }
  end

  def check_webui
    host = ENV.fetch("WEBUI_HOST", "http://open-webui:8080")
    uri = URI.parse("#{host}/api/health")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 5
    
    response = http.get(uri.path)
    
    if response.is_a?(Net::HTTPSuccess)
      {
        connected: true,
        info: "Connected to #{host}",
        status: "Healthy"
      }
    else
      { connected: false, info: "HTTP #{response.code}" }
    end
  rescue => e
    { connected: false, info: e.message }
  end

  def check_qdrant
    host = ENV.fetch("QDRANT_HOST", "http://qdrant:6333")
    uri = URI.parse("#{host}/collections")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 5
    
    response = http.get(uri.path)
    
    if response.is_a?(Net::HTTPSuccess)
      body = JSON.parse(response.body) rescue {}
      collections = body.dig("result", "collections") || []
      {
        connected: true,
        info: "Connected to #{host}",
        collections: collections.map { |c| c["name"] }.join(", ")
      }
    else
      { connected: false, info: "HTTP #{response.code}" }
    end
  rescue => e
    { connected: false, info: e.message }
  end
end
