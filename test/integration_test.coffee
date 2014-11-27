AlertDistributor = require '../src/alert_distributor'
should = require 'should'
sinon = require 'sinon'

describe 'Integration Test', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()

    @newInstance = (eventConfig = {}) =>
      @instance = new AlertDistributor
        events: eventConfig.events
        metrics: eventConfig.metrics
        slack: {}
        pagerduty: key: ''
        log: {}

      for type, dispatcher of @instance.dispatchers
        this["#{type}Mock"] = @sandbox.mock dispatcher

    @packet = (packetString) =>
      @instance.onPacket new Buffer packetString

    @flush = (metrics) =>
      @instance.onFlush new Date(), metrics

    @dispatchesEvents = (types...) =>
      this["#{type}Mock"].expects('sendEvent').once() for type in types

    @noEventsDispatchedFor = (types...) =>
      this["#{type}Mock"].expects('sendEvent').never() for type in types

    @dispatchesMetrics = (types...) =>
      this["#{type}Mock"].expects('sendMetricsEvent').once() for type in types

    @noMetricsDispatchedFor = (types...) =>
      this["#{type}Mock"].expects('sendMetricsEvent').never() for type in types

    @verifyMocks = =>
      this["#{type}Mock"].verify() for type of @instance.dispatchers

  afterEach ->
    @sandbox.restore()

  describe 'packet event handling', ->
    it 'works normally', ->
      @newInstance
        events: [
          name: 'test.slack.event'
          alert: 'slack'
        ,
          name: 'test.pagerduty.event'
          alert: 'pagerduty'
        ,
          name: 'test.log.event'
          alert: 'log'
        ]

      @dispatchesEvents 'slack', 'pagerduty', 'log'

      @packet [
        'test.slack.event:1|c'
        'test.pagerduty.event:1|c'
        'test.log.event:1|c'
      ].join '\n'

      @verifyMocks()

    it 'ignores packets with comparisons that evaluate to false', ->
      @newInstance
        events: [
          name: 'test.slack.event'
          alert: 'slack'
        ,
          name: 'test.pagerduty.event'
          alert: 'pagerduty'
        ,
          name: 'test.log.event'
          gte: 10
          alert: 'log'
        ]

      @dispatchesEvents 'slack', 'pagerduty'
      @noEventsDispatchedFor 'log'

      @packet [
        'test.slack.event:1|c'
        'test.pagerduty.event:1|c'
        'test.log.event:1|c'
      ].join '\n'

      @verifyMocks()

    it 'throws for an event delta comparison', ->
      @newInstance
        events: [
          name: 'test.log.event'
          delta: 10
          alert: 'log'
        ]

      @noEventsDispatchedFor 'log'

      deltaEventError = undefined
      try
        @packet [
          'test.slack.event:1|c'
          'test.pagerduty.event:1|c'
          'test.log.event:1|c'
        ].join '\n'
      catch err
        deltaEventError = err

      should.exist deltaEventError
      deltaEventError.toString().should.eql \
        'Error: delta comparison not supported for event alerts'

      @verifyMocks()

  describe 'flush event handling', ->
    it 'works normally', ->
      @newInstance
        metrics: [
          name: 'test.slack.metric'
          type: 'counter_rates'
          gte: 0.1
          alert: 'slack'
        ,
          name: 'test.pagerduty.metric'
          type: 'timer_data'
          key: 'mean_90'
          lte: 10
          alert: 'pagerduty'
        ,
          name: 'test.log.metric'
          type: 'timer_data'
          key: 'mean_90'
          delta_lt: 10
          alert: 'log'
        ]

      # This is gross. Sorry.
      @instance.lastMetrics =
        timer_data:
          'test.log.metric':
            mean_90: 100

      @dispatchesMetrics 'slack', 'pagerduty', 'log'

      @flush
        counter_rates:
          'test.slack.metric': 0.4
        timer_data:
          'test.pagerduty.metric':
            mean_90: 9
          'test.log.metric':
            mean_90: 70

      @verifyMocks()

    it 'works with wildcards', ->
      @newInstance
        metrics: [
          name: 'test.*.metric'
          type: 'timer_data'
          key: 'mean_90'
          lte: 10
          alert: 'slack'
        ,
          name: 'test.*.metric'
          type: 'timer_data'
          key: 'mean_90'
          delta: 10
          alert: 'log'
        ]

      # This is gross. Sorry.
      @instance.lastMetrics =
        timer_data:
          'test.log.metric':
            mean_90: 100

      # Slack alert should be dispatched twice due to wildcards
      @dispatchesMetrics 'log'
      @slackMock.expects('sendMetricsEvent').twice()

      @flush
        timer_data:
          'test.slack.metric':
            mean_90: 8
          'test.pagerduty.metric':
            mean_90: 9
          'test.log.metric':
            mean_90: 120

      @verifyMocks()

    it 'ignores delta comparison when there are no lastMetrics', ->
      @newInstance
        metrics: [
          name: 'test.log.metric'
          type: 'timer_data'
          key: 'mean_90'
          delta: 10
          alert: 'log'
        ]

      @noMetricsDispatchedFor 'log'

      @flush
        timer_data:
          'test.log.metric':
            mean_90: 70

      @verifyMocks()

    it 'ignores packets with comparisons that evaluate to false', ->
      @newInstance
        metrics: [
          name: 'test.slack.metric'
          type: 'counter_rates'
          gte: 0.1
          alert: 'slack'
        ,
          name: 'test.pagerduty.metric'
          type: 'counter_rates'
          gte: 0.9
          alert: 'pagerduty'
        ]

      @dispatchesMetrics 'slack'
      @noMetricsDispatchedFor 'pagerduty'

      @flush
        counter_rates:
          'test.slack.metric': 0.4
          'test.pagerduty.metric': 0.1

      @verifyMocks()

    it 'works with multiple comparisons', ->
      @newInstance
        metrics: [
          name: 'test.slack.metric'
          type: 'counter_rates'
          gte: 0.1
          alert: 'slack'
        ,
          name: 'test.pagerduty.metric'
          type: 'counter_rates'
          gte: 0.1
          eq: 0.2
          alert: 'pagerduty'
        ]

      @dispatchesMetrics 'slack'
      @noMetricsDispatchedFor 'pagerduty'

      @flush
        counter_rates:
          'test.slack.metric': 0.4
          'test.pagerduty.metric': 0.3

      @verifyMocks()

    it 'works with multiple types of comparisons', ->
      @newInstance
        metrics: [
          name: 'test.pagerduty.metric'
          type: 'counter_rates'
          delta_lt: 0.0
          eq: 0
          alert: 'pagerduty'
        ]

      # This is gross. Sorry.
      @instance.lastMetrics =
        counter_rates:
          'test.pagerduty.metric': 4.8

      @dispatchesMetrics 'pagerduty'

      @flush
        counter_rates:
          'test.pagerduty.metric': 0.0

      @verifyMocks()
