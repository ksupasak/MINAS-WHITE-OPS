require 'rails_helper'

RSpec.describe "post_subjects/show", type: :view do
  before(:each) do
    assign(:post_subject, PostSubject.create!(
      post_id: "Post",
      subject_id: "Subject",
      sentiment: "Sentiment",
      model_id: "Model",
      note: "Note"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Post/)
    expect(rendered).to match(/Subject/)
    expect(rendered).to match(/Sentiment/)
    expect(rendered).to match(/Model/)
    expect(rendered).to match(/Note/)
  end
end
