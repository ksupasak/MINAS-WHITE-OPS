require 'rails_helper'

RSpec.describe "channels/show", type: :view do
  before(:each) do
    assign(:channel, Channel.create!(
      name: "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
  end
end
