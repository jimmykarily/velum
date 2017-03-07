# frozen_string_literal: true
require "rails_helper"

describe "nodes/index" do
  context "regular render" do
    it "has the url on the data-url attribute" do
      render

      section = assert_select(".nodes-container")
      expect(section.attribute("data-url").value).to eq nodes_path
    end

    it "has a button to bootstrap the cluster" do
      render

      section = assert_select("input") { assert_select("[value='Bootstrap Cluster']") }

      text = section[2].attributes["value"].value
      expect(text).to eq "Bootstrap Cluster"
    end

    it "polls for minions" do
      render

      script = assert_select("script").children.text
      expect(script.strip).to match /MinionPoller\.poll/
    end
  end
end
