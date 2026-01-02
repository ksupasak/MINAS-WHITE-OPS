require 'rails_helper'

RSpec.describe "post_subjects/edit", type: :view do
  let(:post_subject) {
    PostSubject.create!(
      post_id: "MyString",
      subject_id: "MyString",
      sentiment: "MyString",
      model_id: "MyString",
      note: "MyString"
    )
  }

  before(:each) do
    assign(:post_subject, post_subject)
  end

  it "renders the edit post_subject form" do
    render

    assert_select "form[action=?][method=?]", post_subject_path(post_subject), "post" do

      assert_select "input[name=?]", "post_subject[post_id]"

      assert_select "input[name=?]", "post_subject[subject_id]"

      assert_select "input[name=?]", "post_subject[sentiment]"

      assert_select "input[name=?]", "post_subject[model_id]"

      assert_select "input[name=?]", "post_subject[note]"
    end
  end
end
