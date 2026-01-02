require "neo4j-ruby-driver"

module Graph
  class Client
    def self.driver
      puts "uri: #{uri}"
      puts "auth_token: #{ENV.fetch("NEO4J_USER", "neo4j")} #{ENV.fetch("NEO4J_PASSWORD", "devpassword")}"

      @driver ||= Neo4j::Driver::GraphDatabase.driver(uri, auth_token,max_connection_pool_size:10,connection_acquisition_timeout:10)
    end

    def self.session(database: nil, **options, &block)
      db = database || ENV.fetch("NEO4J_DATABASE", "neo4j")
      db = 'neo4j'
      driver.session(database: db, **options, &block)
    end

    def self.query(database: nil, cypher:nil, params:nil, **options)
      session(database: database, **options) { |s| s.run(cypher, params) }
    end

    def self.close
      @driver&.close
    end

    def self.uri
      ENV.fetch("NEO4J_URI", "bolt://neo4j:7687")
    end

    def self.auth_token
      Neo4j::Driver::AuthTokens.basic(
        ENV.fetch("NEO4J_USER", "neo4j"),
        ENV.fetch("NEO4J_PASSWORD", "devpassword"),
      )
    end
  end
end
