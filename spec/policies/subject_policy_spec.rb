require "rails_helper"

RSpec.describe SubjectPolicy do
  let!(:customer_one) { create(:customer) }
  let!(:customer_two) { create(:customer) }
  let!(:project_one) { create(:project, customer: customer_one) }
  let!(:project_two) { create(:project, customer: customer_two) }
  let!(:subject_one) { create(:subject, customer: customer_one, project: project_one) }
  let!(:subject_two) { create(:subject, customer: customer_two, project: project_two) }
  let(:user_one) { create(:user, customer: customer_one, role: "admin") }

  describe "scope" do
    it "limits subjects to the user's customer" do
      scope = described_class::Scope.new(user_one, Subject.all).resolve
      expect(scope).to include(subject_one)
      expect(scope).not_to include(subject_two)
    end
  end

  it "allows admins to manage their subjects" do
    policy = described_class.new(user_one, subject_one)
    expect(policy.update?).to be true
    expect(policy.destroy?).to be true
  end

  it "blocks access to other tenants" do
    policy = described_class.new(user_one, subject_two)
    expect(policy.show?).to be false
  end
end
