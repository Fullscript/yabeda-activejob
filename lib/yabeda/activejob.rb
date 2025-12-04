# frozen_string_literal: true

require "yabeda"
require "yabeda/activejob/version"
require "active_support"
require "yabeda/activejob/event_handler"

module Yabeda
  # Small set of metrics on activejob jobs
  module ActiveJob
    LONG_RUNNING_JOB_RUNTIME_BUCKETS = [
      0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, # standard (from Prometheus)
      30, 60, 120, 300, 1800, 3600, 21_600, # In cases jobs are very long-running
    ].freeze

    mattr_accessor :after_event_block, default: proc { |_event| }

    # rubocop: disable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
    def self.install!
      Yabeda.configure do
        group :activejob

        counter :executed_total, tags: %i[queue activejob executions],
                                 comment: "A counter of the total number of activejobs executed."
        counter :enqueued_total, tags: %i[queue activejob executions],
                                 comment: "A counter of the total number of activejobs enqueued."
        counter :scheduled_total, tags: %i[queue activejob executions],
                                  comment: "A counter of the total number of activejobs scheduled for future execution."
        counter :success_total, tags: %i[queue activejob executions],
                                comment: "A counter of the total number of activejobs successfully processed."
        counter :failed_total, tags: %i[queue activejob executions failure_reason],
                               comment: "A counter of the total number of jobs failed for an activejob."

        histogram :runtime, comment: "A histogram of the activejob execution time.",
                            unit: :seconds, per: :activejob,
                            tags: %i[queue activejob executions],
                            buckets: LONG_RUNNING_JOB_RUNTIME_BUCKETS

        histogram :latency, comment: "The job latency, the difference in seconds between enqueued and running time",
                            unit: :seconds, per: :activejob,
                            tags: %i[queue activejob executions],
                            buckets: LONG_RUNNING_JOB_RUNTIME_BUCKETS

        # job complete event
        ActiveSupport::Notifications.subscribe "perform.active_job" do |*args|
          Yabeda::ActiveJob::EventHandler.new(*args).handle_perform
        end

        # start job event
        ActiveSupport::Notifications.subscribe "perform_start.active_job" do |*args|
          Yabeda::ActiveJob::EventHandler.new(*args).handle_perform_start
        end

        # job enqueue event
        ActiveSupport::Notifications.subscribe "enqueue.active_job" do |*args|
          Yabeda::ActiveJob::EventHandler.new(*args).handle_enqueue
        end

        # scheduled job enqueue event
        ActiveSupport::Notifications.subscribe "enqueue_at.active_job" do |*args|
          Yabeda::ActiveJob::EventHandler.new(*args).handle_enqueue_at
        end

        # bulk enqueue event
        ActiveSupport::Notifications.subscribe "enqueue_all.active_job" do |*args|
          Yabeda::ActiveJob::EventHandler.new(*args).handle_enqueue_all
        end
      end
    end
    # rubocop: enable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
  end
end
