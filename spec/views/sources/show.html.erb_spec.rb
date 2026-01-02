require 'rails_helper'

RSpec.describe "sources/show", type: :view do
  before(:each) do
    assign(:source, Source.create!(
      name: "Name",
      channel_id: "Channel"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Channel/)
  end
end
