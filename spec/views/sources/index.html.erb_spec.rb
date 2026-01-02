require 'rails_helper'

RSpec.describe "sources/index", type: :view do
  before(:each) do
    assign(:sources, [
      Source.create!(
        name: "Name",
        channel_id: "Channel"
      ),
      Source.create!(
        name: "Name",
        channel_id: "Channel"
      )
    ])
  end

  it "renders a list of sources" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Channel".to_s), count: 2
  end
end
