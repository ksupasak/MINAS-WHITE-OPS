require 'rails_helper'

RSpec.describe "posts/new", type: :view do
  before(:each) do
    assign(:post, Post.new(
      channel_id: "MyString",
      title: "MyString",
      link: "MyString",
      type: "",
      snippet: "MyString",
      source: "MyString",
      source_id: "MyString",
      raw: "MyString"
    ))
  end

  it "renders new post form" do
    render

    assert_select "form[action=?][method=?]", posts_path, "post" do

      assert_select "input[name=?]", "post[channel_id]"

      assert_select "input[name=?]", "post[title]"

      assert_select "input[name=?]", "post[link]"

      assert_select "input[name=?]", "post[type]"

      assert_select "input[name=?]", "post[snippet]"

      assert_select "input[name=?]", "post[source]"

      assert_select "input[name=?]", "post[source_id]"

      assert_select "input[name=?]", "post[raw]"
    end
  end
end
