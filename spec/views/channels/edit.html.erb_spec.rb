require 'rails_helper'

RSpec.describe "channels/edit", type: :view do
  let(:channel) {
    Channel.create!(
      name: "MyString"
    )
  }

  before(:each) do
    assign(:channel, channel)
  end

  it "renders the edit channel form" do
    render

    assert_select "form[action=?][method=?]", channel_path(channel), "post" do

      assert_select "input[name=?]", "channel[name]"
    end
  end
end
