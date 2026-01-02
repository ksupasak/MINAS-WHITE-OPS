require "rails_helper"

RSpec.describe PostSubjectsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/post_subjects").to route_to("post_subjects#index")
    end

    it "routes to #new" do
      expect(get: "/post_subjects/new").to route_to("post_subjects#new")
    end

    it "routes to #show" do
      expect(get: "/post_subjects/1").to route_to("post_subjects#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/post_subjects/1/edit").to route_to("post_subjects#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/post_subjects").to route_to("post_subjects#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/post_subjects/1").to route_to("post_subjects#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/post_subjects/1").to route_to("post_subjects#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/post_subjects/1").to route_to("post_subjects#destroy", id: "1")
    end
  end
end
