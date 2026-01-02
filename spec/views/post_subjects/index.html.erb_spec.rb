require 'rails_helper'

RSpec.describe "post_subjects/index", type: :view do
  before(:each) do
    assign(:post_subjects, [
      PostSubject.create!(
        post_id: "Post",
        subject_id: "Subject",
        sentiment: "Sentiment",
        model_id: "Model",
        note: "Note"
      ),
      PostSubject.create!(
        post_id: "Post",
        subject_id: "Subject",
        sentiment: "Sentiment",
        model_id: "Model",
        note: "Note"
      )
    ])
  end

  it "renders a list of post_subjects" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Post".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Subject".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Sentiment".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Model".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Note".to_s), count: 2
  end
end
