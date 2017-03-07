# frozen_string_literal: true
require "rails_helper"

feature "Bootstrap cluster feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    visit nodes_path
  end

  scenario "It shows the minions as soon as they register", js: true do
    expect(page).not_to have_content("minion0.k8s.local")
    Minion.create!(hostname: "minion0.k8s.local")
    expect(page).to have_content("minion0.k8s.local")
  end

  scenario "It updates the status of the minions automatically", js: true do
    Minion.create!(hostname: "minion0.k8s.local")
    expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-circle-o")
    Minion.first.update!(highstate: "pending")
    expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-check-circle-o")
  end
end
