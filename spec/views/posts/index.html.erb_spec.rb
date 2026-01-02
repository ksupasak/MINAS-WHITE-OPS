require 'rails_helper'

RSpec.describe "posts/index", type: :view do
  before(:each) do
    assign(:posts, [
      Post.create!(
        channel_id: "Channel",
        title: "Title",
        link: "Link",
        type: "Type",
        snippet: "Snippet",
        source: "Source",
        source_id: "Source",
        raw: "Raw"
      ),
      Post.create!(
        channel_id: "Channel",
        title: "Title",
        link: "Link",
        type: "Type",
        snippet: "Snippet",
        source: "Source",
        source_id: "Source",
        raw: "Raw"
      )
    ])
  end

  it "renders a list of posts" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Channel".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Link".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Type".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Snippet".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Source".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Source".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Raw".to_s), count: 2
  end
end
