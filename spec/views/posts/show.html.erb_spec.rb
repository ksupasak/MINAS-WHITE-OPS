require 'rails_helper'

RSpec.describe "posts/show", type: :view do
  before(:each) do
    assign(:post, Post.create!(
      channel_id: "Channel",
      title: "Title",
      link: "Link",
      type: "Type",
      snippet: "Snippet",
      source: "Source",
      source_id: "Source",
      raw: "Raw"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Channel/)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Link/)
    expect(rendered).to match(/Type/)
    expect(rendered).to match(/Snippet/)
    expect(rendered).to match(/Source/)
    expect(rendered).to match(/Source/)
    expect(rendered).to match(/Raw/)
  end
end
