FactoryBot.define do
  factory :model do
    name { "MyString" }
    config { "MyString" }
    version { "MyString" }
    host { "MyString" }
    token { "MyString" }
  end

  factory :post_subject do
    post_id { "MyString" }
    subject_id { "MyString" }
    sentiment { "MyString" }
    model_id { "MyString" }
    note { "MyString" }
  end

  factory :source do
    name { "MyString" }
    channel_id { "MyString" }
  end

  factory :post do
    channel_id { "MyString" }
    title { "MyString" }
    link { "MyString" }
    type { "" }
    snippet { "MyString" }
    source { "MyString" }
    source_id { "MyString" }
    raw { "MyString" }
  end

  factory :channel do
    name { "MyString" }
  end

  factory :customer do
    sequence(:name) { |n| "Customer #{n}" }
    sequence(:slug) { |n| "customer-#{n}" }
    plan { "pro" }
    status { "active" }
  end

  factory :user do
    association :customer
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "admin" }
  end

  factory :project do
    association :customer
    sequence(:name) { |n| "Project #{n}" }
    description { "Test project" }
    status { "active" }
  end

  factory :subject do
    association :project
    customer { project.customer }
    sequence(:name) { |n| "Subject #{n}" }
    query { "#test" }
    language { "en" }
    country { "US" }
    active { true }
  end

  factory :feeder_type do
    sequence(:name) { |n| "Type#{n}" }
    description { "Adapter" }
  end

  factory :feeder do
    association :customer
    association :feeder_type
    sequence(:name) { |n| "Feeder #{n}" }
    status { "idle" }
    schedule_cron { "*/5 * * * *" }
  end

  factory :result do
    association :feeder
    customer { feeder.customer }
    status { "finished" }
    posts_count { 1 }
    users_count { 1 }
    hashtags_count { 1 }
    subject_ids { [] }
  end
end
