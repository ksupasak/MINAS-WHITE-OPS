class TestController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    @redis_status = check_redis
    @mongo_status = check_mongo
    @neo4j_status = check_neo4j
  end

  def neo4j
  end

  private

  def check_redis
    redis_url = ENV.fetch("REDIS_URL", "redis://redis:6379/0")
    redis = Redis.new(url: redis_url)
    redis.ping
    { connected: true, info: "Connected to #{redis_url}" }
  rescue => e
    { connected: false, info: e.message }
  ensure
    redis&.close
  end

  def check_mongo
    mongo_uri = Mongoid.default_client.cluster.addresses.map(&:to_s).join(", ")
    Mongoid.default_client.database.command(ping: 1)
    { connected: true, info: "Connected to #{mongo_uri}" }
  rescue => e
    { connected: false, info: e.message }
  end

  def check_neo4j
    neo4j_uri = Graph::Client.uri
    session = Graph::Client.session 
    session.run("RETURN 1")
    # session.close if session.respond_to?(:close)
   
    { connected: true, info: "Connected to #{neo4j_uri}" }
  rescue => e
    puts neo4j_uri
    puts e.message
    puts e.backtrace.join("\n")
    { connected: false, info: e.message }
  end
end
