require 'rails_helper'

RSpec.describe "sources/new", type: :view do
  before(:each) do
    assign(:source, Source.new(
      name: "MyString",
      channel_id: "MyString"
    ))
  end

  it "renders new source form" do
    render

    assert_select "form[action=?][method=?]", sources_path, "post" do

      assert_select "input[name=?]", "source[name]"

      assert_select "input[name=?]", "source[channel_id]"
    end
  end
end
