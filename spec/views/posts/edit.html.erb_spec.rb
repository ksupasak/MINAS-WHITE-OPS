require 'rails_helper'

RSpec.describe "posts/edit", type: :view do
  let(:post) {
    Post.create!(
      channel_id: "MyString",
      title: "MyString",
      link: "MyString",
      type: "",
      snippet: "MyString",
      source: "MyString",
      source_id: "MyString",
      raw: "MyString"
    )
  }

  before(:each) do
    assign(:post, post)
  end

  it "renders the edit post form" do
    render

    assert_select "form[action=?][method=?]", post_path(post), "post" do

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
