require 'rails_helper'

RSpec.describe "post_subjects/new", type: :view do
  before(:each) do
    assign(:post_subject, PostSubject.new(
      post_id: "MyString",
      subject_id: "MyString",
      sentiment: "MyString",
      model_id: "MyString",
      note: "MyString"
    ))
  end

  it "renders new post_subject form" do
    render

    assert_select "form[action=?][method=?]", post_subjects_path, "post" do

      assert_select "input[name=?]", "post_subject[post_id]"

      assert_select "input[name=?]", "post_subject[subject_id]"

      assert_select "input[name=?]", "post_subject[sentiment]"

      assert_select "input[name=?]", "post_subject[model_id]"

      assert_select "input[name=?]", "post_subject[note]"
    end
  end
end
