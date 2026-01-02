require 'rails_helper'

RSpec.describe "models/show", type: :view do
  before(:each) do
    assign(:model, Model.create!(
      name: "Name",
      config: "Config",
      version: "Version",
      host: "Host",
      token: "Token"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Config/)
    expect(rendered).to match(/Version/)
    expect(rendered).to match(/Host/)
    expect(rendered).to match(/Token/)
  end
end
