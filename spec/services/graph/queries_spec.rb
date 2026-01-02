require "rails_helper"

RSpec.describe Graph::Queries do
  let(:customer) { create(:customer) }
  let(:service) { described_class.new(customer: customer) }

  describe "#subject_graph" do
    it "returns nodes and edges from neo4j payload" do
      records = [
        {
          "p" => { "id" => "1", "text" => "Hello world" },
          "u" => { "id" => "u1", "username" => "alice" },
          "h" => { "tag" => "acme" },
          "c" => { "name" => "X" }
        }
      ]

      allow(Graph::Client).to receive(:query).and_return(double(to_a: records))

      data = service.subject_graph(subject_id: "s1")
      ids = data[:nodes].map { |n| n[:id] }
      expect(ids).to include("post-1", "user-u1", "tag-acme", "channel-X")
      expect(data[:edges]).not_to be_empty
    end
  end

  describe "analytics queries" do
    it "returns top hashtags" do
      allow(Graph::Client).to receive(:query).and_return([{ "tag" => "acme", "count" => 3 }])
      results = service.top_hashtags(subject_id: nil)
      expect(results.first[:tag]).to eq("acme")
      expect(results.first[:count]).to eq(3)
    end

    it "returns top users" do
      allow(Graph::Client).to receive(:query).and_return([{ "user_id" => "u1", "username" => "alice", "count" => 2 }])
      results = service.top_users(subject_id: nil)
      expect(results.first[:user_id]).to eq("u1")
      expect(results.first[:count]).to eq(2)
    end
  end
end
