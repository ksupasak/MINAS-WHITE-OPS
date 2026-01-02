require 'rails_helper'

RSpec.describe "models/index", type: :view do
  before(:each) do
    assign(:models, [
      Model.create!(
        name: "Name",
        config: "Config",
        version: "Version",
        host: "Host",
        token: "Token"
      ),
      Model.create!(
        name: "Name",
        config: "Config",
        version: "Version",
        host: "Host",
        token: "Token"
      )
    ])
  end

  it "renders a list of models" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Config".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Version".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Host".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Token".to_s), count: 2
  end
end
