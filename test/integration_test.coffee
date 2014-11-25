AlertDistributor = require '../src/alert_distributor'
should = require 'should'
sinon = require 'sinon'

describe.only 'Integration Test', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()

    @newInstance = (eventConfig = {}) =>
      @instance = new AlertDistributor
        events: eventConfig.events
        metrics: eventConfig.metrics
        slack: {}
        pagerduty: key: ''
        log: {}
        email: {}

      for type, dispatcher of @instance.dispatchers
        this["#{type}Mock"] = @sandbox.mock dispatcher

    @packet = (packetString) =>
      @instance.onPacket new Buffer packetString

    @flush = (metrics) =>
      @instance.onFlush new Date(), metrics

    @dispatchesEvents = (types...) =>
      this["#{type}Mock"].expects('sendEvent').once() for type in types

    @dispatchesMetrics = (types...) =>
      this["#{type}Mock"].expects('sendMetricsEvent').once() for type in types

    @verify = =>
      this["#{type}Mock"].verify() for type of @instance.dispatchers

  afterEach ->
    @sandbox.restore()

  describe 'packet event handling', ->
    it 'should work', ->
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

      @verify()

  describe 'flush event handling', ->
    it 'should work', ->
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
          delta: 10
          alert: 'log'
        ]

      # This is gross. Sorry.
      @instance.lastMetrics = timer_data: mean_90: 100

      @dispatchesMetrics 'slack', 'pagerduty', 'log'

      @flush
        counter_rates:
          'test.slack.metric': 0.4
        timer_data:
          'test.pagerduty.metric': mean_90: 9
          'test.log.metric': mean_90: 70

      @verify()
