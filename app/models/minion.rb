# frozen_string_literal: true

require "velum/salt_minion"
require "velum/salt"

# Minion represents the minions that have been registered in this application.
class Minion < ApplicationRecord
  # Raised when Minion doesn't exist
  class NonExistingMinion < StandardError; end

  enum highstate: [:not_applied, :pending, :failed, :applied]
  enum role: [:master, :minion]

  validates :hostname, presence: true, uniqueness: true

  # Example:
  #   Minion.assign_roles(
  #     roles: {
  #       "master.example.com" => ["master"],
  #       "minion1.example.com" => ["minion"]
  #     },
  #     default_role: :dns
  #   )
  def self.assign_roles!(roles: {}, default_role: :minion)
    requested_master = roles.detect { |_name, r| r.include?("master") }.first
    requested_minions = roles.select { |_name, r| r.include?("minion") }.keys
    if roles.values.flatten.include?("master") && !Minion.exists?(hostname: requested_master)
      raise NonExistingMinion, "Failed to process non existing minion: #{requested_master}"
    end
    master = Minion.find_by(hostname: requested_master)
    # choose requested minions or all other than master
    minions = Minion.where(hostname: requested_minions).where.not(hostname: requested_master)

    # assign master if requested
    {}.tap do |ret|
      ret[master.hostname] = master.assign_role(:master) if master

      minions.find_each do |minion|
        ret[minion.hostname] = minion.assign_role(:minion)
      end

      # assign default role if there is any minion left with no role
      if default_role
        Minion.where(role: nil).find_each do |minion|
          ret[minion.hostname] = minion.assign_role(default_role)
        end
      end
    end
  end

  # This method is used to collect the specs of each Minion (RAM/CPU/etc).
  # The user might need this information in order to decide which Minion
  # is going to be the kubernetes master or minion.
  def self.collect_specs(hostnames: [], spec:)
    return {} unless hostnames.any?

    spec_map = {
      "cpu" => "cat /proc/cpuinfo | grep -E 'model name|cpu cores|cpu MHz'",
      "ram" => "cat /proc/meminfo | grep -E 'MemTotal'"
    }

    result = Velum::Salt.call(action: "cmd.run",
                              targets: hostnames.join(','),
                              arg: spec_map[spec])[1]

    result["return"].first
  end

  def collect_specs(spec)
    self.class.collect_specs(hostnames: [self.hostname], spec: spec).values.first
  end

  # rubocop:disable SkipsModelValidations
  # Assigns a role to this minion locally in the database, and send that role
  # to salt subsystem.
  def assign_role(new_role)
    return false if role.present?
    success = false

    Minion.transaction do
      # We set highstate to pending since we just assigned a new role
      success = update_columns(role:      Minion.roles[new_role],
                               highstate: Minion.highstates[:pending])
      break unless success
      success = salt.assign_role new_role
    end
    success
  rescue Velum::SaltApi::SaltConnectionException
    errors.add(:base, "Failed to apply role #{new_role} to #{hostname}")
    false
  end
  # rubocop:enable SkipsModelValidations

  # Returns the proxy for the salt minion
  def salt
    @salt ||= Velum::SaltMinion.new minion_id: hostname
  end
end
