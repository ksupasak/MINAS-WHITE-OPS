# Social Monitoring Platform

Multi-tenant social monitoring app on Rails 7, Mongoid (MongoDB) for primary data, Neo4j for graph storage/visualization, Devise authentication, and Pundit authorization. Sidekiq/Redis handle background feeder jobs. Bootstrap 5 powers the admin UI and Cytoscape.js renders graph views.

## Requirements
- Ruby 3.2.2
- MongoDB 7+
- Neo4j 5+ (bolt)
- TigerGraph (optional via REST++, see docker-compose)
- Redis 7+ (Sidekiq)

## Setup
1) Install dependencies and gems
```bash
bundle install
bin/setup
```

2) Configure env vars (.env from .env.example)
```
cp .env.example .env
# update MONGODB_URI, NEO4J_*, REDIS_URL, SECRET_KEY_BASE, DEVISE_SECRET_KEY
```

3) Database/graph config
```
rails db:seed   # loads db/seeds.rb using Mongoid
```

4) Run services
```bash
foreman start -f Procfile.dev # or rails server + sidekiq separately
```

### Docker
```bash
docker compose up --build
# web: http://localhost:3000, neo4j browser: http://localhost:7474
```

### Seeds / Demo Login
- Admin (super_admin): `admin@example.com / password123`
- Customer admin: `owner@example.com / password123`
Seeds also create demo customer, project, subjects, feeder, and sample graph batch.

## Background Jobs
- Sidekiq + sidekiq-cron (`config/sidekiq_schedule.yml`) for scheduled feeders
- Enqueue manual run from Feeders UI “Run now” button
- SerpAPI adapter supported (FeederType "SERPAPI"); configure API key + search params in Feeder Config. Manual run via `RunSerpapiFeederJob` or `rake feeders:run_serpapi[feeder_id,subject_id]`.
- Graph store: Neo4j by default; set `TIGERGRAPH_ENABLED=true` with TigerGraph env vars to fetch graph data via REST++ for the Graph view and analytics APIs.
- LLM sentiment (Ollama): optional `ollama` + `open-webui` services in docker-compose. Set `OLLAMA_HOST` and `OLLAMA_MODEL` (default `qwen2.5:1.5b`). Call `POST /api/v1/sentiment` with `{ text: "..." }` (auth required) to get sentiment.

## Graph APIs
- `GET /api/v1/graph?subject_id=...&from=...&to=...`
- `GET /api/v1/analytics/top_hashtags?subject_id=...`
- `GET /api/v1/analytics/top_users?subject_id=...`
Responses are tenant-scoped and suitable for Cytoscape.js.

## Testing
```bash
bundle exec rspec
```
Includes tenant scoping, policy, and graph service unit coverage.

## Tenant Model
- Customer -> Projects -> Subjects
- Users belong_to Customer; scopes enforced via Pundit scopes and `Current.customer`
- Feeder/Result scoped by customer_id; super_admin bypasses tenant isolation.
