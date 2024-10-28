# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Yabeda::ActiveJob, type: :integration do
  include ActionDispatch::Integration::Runner
  include ActionDispatch::IntegrationTest::Behavior
  include ActiveJob::TestHelper

  before do |ex|
    ActiveJob::Base.queue_adapter = ex.metadata[:queue_adapter] || :inline
  end

  after { described_class.after_event_block = proc {} }

  context "when job is successful" do
    it "increments successful job counter" do
      expect { HelloJob.perform_later }.to \
        increment_yabeda_counter(Yabeda.activejob.success_total)
        .with_tags(queue: "default", activejob: "HelloJob", executions: "1")
        .by(1)
    end

    it "runs the after_event_block successfully" do
      random_double = double
      allow(random_double).to receive(:hello).with(an_instance_of(ActiveSupport::Notifications::Event))
      described_class.after_event_block = proc { |event| random_double.hello(event) }
      HelloJob.perform_later

      expect(random_double).to have_received(:hello).exactly(3).times
    end

    it "does not increment failed job counter" do
      expect { HelloJob.perform_later }.to not_increment_yabeda_counter(Yabeda.activejob.failed_total)
    end

    it "increments executed job counter" do
      expect { HelloJob.perform_later }.to \
        increment_yabeda_counter(Yabeda.activejob.executed_total)
        .with_tags(queue: "default", activejob: "HelloJob", executions: "1")
        .by(1)
    end

    it "measures job runtime" do
      expect { LongJob.perform_later }.to \
        measure_yabeda_histogram(Yabeda.activejob.runtime)
        .with_tags(queue: "default", activejob: "LongJob", executions: "1")
        .with(be_between(0.005, 0.05))
    end

    it "measures job latency", queue_adapter: :test do
      expect { HelloJob.perform_later }.to have_enqueued_job.on_queue("default")
      expect { perform_enqueued_jobs }.to measure_yabeda_histogram(Yabeda.activejob.latency)
        .with_tags(queue: "default", activejob: "HelloJob", executions: "1")
        .with(kind_of(Float))
    end

    context "when enqueued_at is not present" do
      it "does not measure job latency", queue_adapter: :test do
        allow_any_instance_of(HelloJob).to receive(:enqueued_at).and_return(nil) # rubocop:disable RSpec/AnyInstance

        expect { HelloJob.perform_later }.to have_enqueued_job.on_queue("default")
        sleep(1)
        expect { perform_enqueued_jobs }.not_to measure_yabeda_histogram(Yabeda.activejob.latency)
      end
    end
  end

  context "when job fails" do
    it "increments failed job counter" do
      expect { ErrorJob.perform_later }.to increment_yabeda_counter(Yabeda.activejob.failed_total)
        .with_tags(
          queue: "default",
          activejob: "ErrorJob",
          executions: "1",
          failure_reason: "StandardError",
        ).by(1).and(raise_error(StandardError))
    end

    it "increments executed job counter" do
      expect { ErrorJob.perform_later }.to \
        increment_yabeda_counter(Yabeda.activejob.executed_total)
        .with_tags(queue: "default", activejob: "ErrorJob", executions: "1")
        .by(1).and(raise_error(StandardError))
    end

    it "does not increment success job counter" do
      expect { ErrorJob.perform_later }
        .to not_increment_yabeda_counter(Yabeda.activejob.success_total)
        .and(raise_error(StandardError))
    end

    it "measures job runtime" do
      expect { ErrorLongJob.perform_later }.to \
        measure_yabeda_histogram(Yabeda.activejob.runtime)
        .with_tags(queue: "default", activejob: "ErrorLongJob", executions: "1")
        .with(be_between(0.005, 0.05))
        .and(raise_error(StandardError))
    end

    it "runs the after_event_block successfully" do
      random_double = double
      allow(random_double).to receive(:hello).with(an_instance_of(ActiveSupport::Notifications::Event))
      described_class.after_event_block = proc { |event| random_double.hello(event) }

      expect { ErrorLongJob.perform_later }.to raise_error(StandardError)

      expect(random_double).to have_received(:hello).exactly(3).times
    end
  end

  context "when job is enqueued", queue_adapter: :test do
    it "increments enqueued job counter" do
      expect do
        HelloJob.perform_later
      end.to have_enqueued_job.on_queue("default").and(
        increment_yabeda_counter(Yabeda.activejob.enqueued_total)
          .with_tags(queue: "default", activejob: "HelloJob", executions: "0")
          .by(1),
      )
    end

    it "runs the after_event_block successfully" do
      random_double = double
      allow(random_double).to receive(:hello).with(an_instance_of(ActiveSupport::Notifications::Event))
      described_class.after_event_block = proc { |event| random_double.hello(event) }

      HelloJob.perform_later

      expect(random_double).to have_received(:hello)
    end
  end
end
