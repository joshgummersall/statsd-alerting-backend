Alerts = require './alerts'
_ = require 'underscore'
wildcard = require 'wildcard'

# Mixin for number-ish testing
_.mixin
  isNumbery: (toTest = '') ->
    not _.isNaN Number toTest

module.exports = class AlertDistributor
  # Comparison functions for metrics events
  @COMPARISONS:
    gte: (a, b) -> a >= b
    gt: (a, b) -> a > b
    lte: (a, b) -> a <= b
    lt: (a, b) -> a < b
    delta: (a, b) -> a >= b

  constructor: (@config = {}) ->
    # Register events to dispatch alerts for
    @events = @config.events or []
    @metrics = @config.metrics or []

    # Build dispatchers for events
    @dispatchers = {}
    @dispatchers[type] = new klass @config[type] for type, klass of Alerts \
      when type of @config

  dispatchEvent: (type, event) ->
    throw new Error 'Undefined events alert type' unless type of @dispatchers
    @dispatchers[type].sendEvent event

  dispatchMetricsEvent: (type, event) ->
    throw new Error 'Undefined metrics alert type' unless type of @dispatchers
    @dispatchers[type].sendMetricsEvent event

  # Parse out event data from StatsD packet
  parsePacket: (packet) ->
    for event in packet.toString().split('\n') or []
      [name, data] = event.split ':'
      [metric, type] = data.split '|'
      metric = Number metric if _.isNumbery metric
      {name, metric, type}

  # Matches using exact event or wildcard matching. I.e., "some.event.here"
  # will match against "some.event.here" or "some.*"
  # Note: `event.name` is what is listed in the configuration file
  matchEvent: (event, name) ->
    return true if event.name is name
    wildcard(event.name, name)?.length > 0

  # Note: bound with fat arrow because it is passed as a function to
  # an event emitter binding and we want it bound to the instance
  onPacket: (packet, rinfo) =>
    for {name, metric, type} in @parsePacket packet
      for event in @events when @matchEvent event, name
        # Note: the first argument to `extend` helps simulate a deep clone
        @dispatchEvent event.alert, _.extend {}, event, {name, metric, type}

  # Extract metric comparison type and value from event properties defined
  # in configuration file.
  getMetricComparison: (eventConfig) ->
    for key of @constructor.COMPARISONS when key of eventConfig
      comparison = key
      value = eventConfig[key]
      return {comparison, value}

  # Perform comparison using comparison functions defined above
  doComparison: (comparison, eventMetric, alertValue) ->
    compareFn = @constructor.COMPARISONS[comparison.toLowerCase()]
    compareFn?(eventMetric, alertValue) ? false

  # Note: bound with fat arrow because it is passed as a function to
  # an event emitter binding and we want it bound to the instance
  onFlush: (timestamp, metrics) =>
    # Helper to extract a metric from StatsD flush
    getMetric = (metrics) ->
      (type, name, key) ->
        return unless metrics?
        keys = _.compact [type, name, key]
        tmp = metrics
        tmp = tmp[key] for key in keys when key of tmp
        tmp

    getCurrentMetric = getMetric metrics
    getLastMetric = getMetric @lastMetrics

    for event in @metrics
      # Extract alert configuration
      {name, type, key} = event
      {comparison, value} = @getMetricComparison event

      continue unless comparison? and value?

      # Extract metric
      if comparison is 'delta'
        # We compute the absolute value of the delta
        currentMetric = getCurrentMetric type, name, key
        lastMetric = getLastMetric type, name, key
        eventMetric = if currentMetric and lastMetric \
          then Math.abs currentMetric - lastMetric else 0
      else
        eventMetric = getCurrentMetric type, name, key

      continue unless eventMetric? and _.isNumber eventMetric

      # Tag on metric for alert
      event.metric = eventMetric

      # Compare and dispatch. Note: the first argument to @doComparison is the
      # actual computed metric sent from StatsD, the second is the configured value
      # to alert
      @dispatchMetricsEvent event.alert, event \
        if @doComparison comparison, eventMetric, value

    # Store metrics for delta comparisons
    @lastMetrics = metrics
