require 'rails_helper'

RSpec.describe "models/new", type: :view do
  before(:each) do
    assign(:model, Model.new(
      name: "MyString",
      config: "MyString",
      version: "MyString",
      host: "MyString",
      token: "MyString"
    ))
  end

  it "renders new model form" do
    render

    assert_select "form[action=?][method=?]", models_path, "post" do

      assert_select "input[name=?]", "model[name]"

      assert_select "input[name=?]", "model[config]"

      assert_select "input[name=?]", "model[version]"

      assert_select "input[name=?]", "model[host]"

      assert_select "input[name=?]", "model[token]"
    end
  end
end
