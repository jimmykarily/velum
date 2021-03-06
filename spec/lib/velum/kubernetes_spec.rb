# frozen_string_literal: true
require "rails_helper"
require "velum/kubernetes"

describe Velum::Kubernetes do
  before do
    ENV["VELUM_KUBERNETES_HOST"] = "example.test.lan"
    ENV["VELUM_KUBERNETES_PORT"] = "5900"
    ENV["VELUM_KUBERNETES_CERT_DIRECTORY"] = Rails.root.join("spec", "fixtures").to_s
  end

  it "initializes properly" do
    endpoint = described_class.new.client.api_endpoint

    url = "#{endpoint.host}:#{endpoint.port}#{endpoint.path}"
    expect(url).to eq "example.test.lan:5900/api"
  end
end
