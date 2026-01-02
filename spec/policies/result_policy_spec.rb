require "rails_helper"

RSpec.describe ResultPolicy do
  let(:customer) { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:feeder) { create(:feeder, customer: customer, feeder_type: create(:feeder_type)) }
  let!(:result_one) { create(:result, feeder: feeder, customer: customer) }
  let!(:result_two) { create(:result, feeder: create(:feeder, customer: other_customer, feeder_type: create(:feeder_type)), customer: other_customer) }
  let(:user) { create(:user, customer: customer, role: "member") }

  it "scopes results to the user's customer" do
    scope = described_class::Scope.new(user, Result.all).resolve
    expect(scope).to include(result_one)
    expect(scope).not_to include(result_two)
  end

  it "allows viewing own tenant results" do
    policy = described_class.new(user, result_one)
    expect(policy.show?).to be true
  end
end
