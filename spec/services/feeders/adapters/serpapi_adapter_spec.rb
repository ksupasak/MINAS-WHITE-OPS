require "rails_helper"

RSpec.describe Feeders::Adapters::SerpapiAdapter do
  let(:customer) { create(:customer) }
  let(:feeder_type) { create(:feeder_type, name: "SERPAPI") }
  let(:feeder) { create(:feeder, customer: customer, feeder_type: feeder_type) }
  let!(:config) { feeder.create_feeder_config!(api_key: "demo", engine: "google") }
  let(:project) { create(:project, customer: customer) }
  let(:subject) { create(:subject, customer: customer, project: project, query: "acme") }

  it "normalizes serpapi organic results" do
    adapter = described_class.new(feeder: feeder)
    allow(adapter).to receive(:perform_search).and_return({
      "organic_results" => [
        {
          "position" => 1,
          "title" => "Acme News",
          "snippet" => "Latest about #acme",
          "displayed_link" => "example.com/acme"
        }
      ]
    })

    items = adapter.fetch(feeder: feeder, subject: subject)
    expect(items.first[:channel]).to eq("SERPAPI")
    expect(items.first[:hashtags]).to include("acme")
    expect(items.first[:post_id]).to eq(1)
  end
end
