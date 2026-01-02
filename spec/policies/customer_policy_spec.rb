require "rails_helper"

RSpec.describe CustomerPolicy do
  let(:customer) { create(:customer) }
  let(:user) { create(:user, customer: customer, role: "admin") }
  let(:super_admin) { create(:user, customer: customer, role: "super_admin") }

  it "denies non super-admin access" do
    policy = described_class.new(user, customer)
    expect(policy.index?).to be false
    expect(policy.show?).to be false
  end

  it "allows super-admin full access" do
    policy = described_class.new(super_admin, customer)
    expect(policy.index?).to be true
    expect(policy.create?).to be true
    expect(policy.destroy?).to be true
  end
end
