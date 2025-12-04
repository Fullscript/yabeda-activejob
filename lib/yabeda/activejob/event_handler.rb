# frozen_string_literal: true

class Yabeda::ActiveJob::EventHandler
  def initialize(*event_args)
    @event = ActiveSupport::Notifications::Event.new(*event_args)
  end

  def handle_perform
    labels = {
      activejob: event.payload[:job].class.to_s,
      queue: event.payload[:job].queue_name.to_s,
      executions: event.payload[:job].executions.to_s,
    }
    if event.payload[:exception].present?
      Yabeda.activejob_failed_total.increment(
        labels.merge(failure_reason: event.payload[:exception].first.to_s),
      )
    else
      Yabeda.activejob_success_total.increment(labels)
    end

    Yabeda.activejob_executed_total.increment(labels)
    Yabeda.activejob_runtime.measure(labels, ms2s(event.duration))
    call_after_event_block
  end

  def handle_perform_start
    labels = common_labels(event.payload[:job])

    job_latency_value = job_latency
    Yabeda.activejob_latency.measure(labels, job_latency_value) if job_latency_value.present?
    call_after_event_block
  end

  def handle_enqueue
    labels = common_labels(event.payload[:job])

    Yabeda.activejob_enqueued_total.increment(labels)

    call_after_event_block
  end

  def handle_enqueue_at
    labels = common_labels(event.payload[:job])

    Yabeda.activejob_scheduled_total.increment(labels)

    call_after_event_block
  end

  def handle_enqueue_all
    event.payload[:jobs].each do |job|
      labels = common_labels(job)

      if job.scheduled_at
        Yabeda.activejob_scheduled_total.increment(labels)
      else
        Yabeda.activejob_enqueued_total.increment(labels)
      end
    end

    call_after_event_block
  end

  private
    attr_reader :event

    def job_latency
      if enqueue_time = event.payload[:job].enqueued_at
        enqueue_time = parse_event_time(enqueue_time)
        perform_at_time = parse_event_time(event.end)

        perform_at_time - enqueue_time
      end
    end

    def ms2s(milliseconds)
      (milliseconds.to_f / 1000).round(3)
    end

    def parse_event_time(time)
      case time
      when Time   then time
      when String then Time.parse(time).utc
      else
        if time > 1e12
          Time.at(ms2s(time)).utc
        else
          Time.at(time).utc
        end
      end
    end

    def common_labels(job)
      Yabeda.default_tags.reverse_merge(
        activejob: job.class.to_s,
        queue: job.queue_name,
        executions: job.executions.to_s,
      )
    end

    def call_after_event_block
      Yabeda::ActiveJob.after_event_block.call(event) if Yabeda::ActiveJob.after_event_block.respond_to?(:call)
    end
end
