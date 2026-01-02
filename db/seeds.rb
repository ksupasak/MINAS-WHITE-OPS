puts "Seeding demo data..."

customer = Customer.find_or_create_by!(slug: "demo") do |c|
  c.name = "Demo Customer"
  c.plan = "pro"
  c.status = "active"
end

super_admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "super_admin"
  u.customer = customer
end

admin_user = User.find_or_create_by!(email: "owner@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "admin"
  u.customer = customer
end

project = customer.projects.find_or_create_by!(name: "Brand Watch") do |p|
  p.description = "Monitoring brand mentions"
  p.status = "active"
end

subject1 = project.subjects.find_or_create_by!(name: "#acme") do |s|
  s.query = "#acme"
  s.language = "en"
  s.country = "US"
  s.active = true
  s.customer = customer
end

subject2 = project.subjects.find_or_create_by!(name: "Acme keyword") do |s|
  s.query = "Acme"
  s.language = "en"
  s.country = "US"
  s.active = true
  s.customer = customer
end

feeder_types = {
  "X" => "X/Twitter adapter",
  "Instagram" => "Instagram adapter",
  "Facebook" => "Facebook adapter",
  "SERPAPI" => "Web search via SerpAPI"
}

feeder_types.each do |name, desc|
  FeederType.find_or_create_by!(name: name) { |ft| ft.description = desc }
end

feeder_type = FeederType.find_by(name: "X")

feeder = customer.feeders.find_or_create_by!(name: "Demo Feeder") do |f|
  f.feeder_type = feeder_type
  f.status = "idle"
  f.schedule_cron = "*/30 * * * *"
end

# feeder.create_feeder_config!(
#   api_key: "demo",
#   api_secret: "demo",
#   access_token: "demo",
#   refresh_token: "demo",
#   base_url: "https://api.demo",
#   rate_limit_policy: "standard",
#   extra: { note: "demo credentials" }
# ) unless feeder.feeder_config

[subject1, subject2].each do |subject|
  feeder.feeder_subjects.find_or_create_by!(subject: subject)
end

items = [
  {
    post_id: "seed-post-1",
    user_id: "seed-user-1",
    username: "demo_user",
    channel: "X",
    text: "Seed post about ##{subject1.query}",
    created_at: Time.current,
    hashtags: ["acme"],
    ref_type: "post",
    ref_post_id: nil
  },
  {
    post_id: "seed-post-2",
    user_id: "seed-user-2",
    username: "another_user",
    channel: "Instagram",
    text: "Another mention for #{subject2.query}",
    created_at: Time.current,
    hashtags: ["acme", "launch"],
    ref_type: "reply",
    ref_post_id: "seed-post-1"
  }
]

begin
  Graph::UpsertBatch.new(customer: customer, feeder: feeder, subject_ids: [subject1.id, subject2.id], items: items).call
rescue StandardError => e
  warn "Graph seed skipped: #{e.message}"
end

feeder.results.create!(
  customer: customer,
  project: project,
  subject_ids: [subject1.id, subject2.id],
  status: "finished",
  posts_count: items.count,
  users_count: items.map { |i| i[:user_id] }.uniq.count,
  hashtags_count: items.sum { |i| Array(i[:hashtags]).size },
  started_at: Time.current - 5.minutes,
  finished_at: Time.current
)

puts "Seed complete. Login with admin@example.com / password123"
