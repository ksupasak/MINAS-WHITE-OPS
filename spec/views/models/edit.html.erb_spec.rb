require 'rails_helper'

RSpec.describe "models/edit", type: :view do
  let(:model) {
    Model.create!(
      name: "MyString",
      config: "MyString",
      version: "MyString",
      host: "MyString",
      token: "MyString"
    )
  }

  before(:each) do
    assign(:model, model)
  end

  it "renders the edit model form" do
    render

    assert_select "form[action=?][method=?]", model_path(model), "post" do

      assert_select "input[name=?]", "model[name]"

      assert_select "input[name=?]", "model[config]"

      assert_select "input[name=?]", "model[version]"

      assert_select "input[name=?]", "model[host]"

      assert_select "input[name=?]", "model[token]"
    end
  end
end
