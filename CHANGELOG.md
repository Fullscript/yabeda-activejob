## 0.5.0 - 2023-11-01
- Add support for rails 7.1 Shout out to @bronislav for getting this done!!

## 0.4.0 - 20220-11-04

- Add feature `after_event_block` it gets called with every notification

## 0.3.1 - 20220-10-29

- Fix a bug where when `enqueued_at` was not set on instance variable lead to failure

## 0.3.0 - 20220-10-29

- Add enqueued_total counter

## 0.2.0 - 20220-10-22

- Change metric names such that they no longer sound repetitive when using the word job, eg `activejob_job_success_total` is now `activejob_success_total`. See Readme for more details.
- Added some badges to repo
- Remove erroneous put statement

## 0.1.0 - 20220-10-21

- Initial release of yabeda-activejob gem. @etsenake

  Yabeda metrics around rails activejobs. See Readme for more details.
