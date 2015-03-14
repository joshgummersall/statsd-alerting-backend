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
    eq: (a, b) -> a is b
    delta: (a, b) -> a >= b
    delta_gte: (a, b) -> a >= b
    delta_gt: (a, b) -> a > b
    delta_lte: (a, b) -> a <= b
    delta_lt: (a, b) -> a < b
    delta_eq: (a, b) -> a is b

  isDelta: (comparison = '') ->
    comparison.toLowerCase().indexOf('delta') is 0

  constructor: (@config = {}) ->
    # Register events to dispatch alerts for
    @events = @config.events or []
    @metrics = @config.metrics or []

    # Build dispatchers for event
    @dispatchers = {}
    for name, {type, config} of @config.dispatchers when type of Alerts
      @dispatchers[name] = new Alerts[type] config

  dispatchEvent: (name, event) ->
    throw new Error "#{name} is not a valid events alert dispatcher" \
      unless name of @dispatchers
    @dispatchers[name].sendEvent event

  dispatchMetricsEvent: (name, event) ->
    throw new Error "#{name} is not a valid metrics alert dispatcher" \
      unless name of @dispatchers
    @dispatchers[name].sendMetricsEvent event

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
  wildcardMatch: (a, b) ->
    return true if a.toLowerCase() is b.toLowerCase()
    wildcard(a, b)?.length > 0

  matchEvent: (event, name) ->
    @wildcardMatch event.name, name

  # Note: bound with fat arrow because it is passed as a function to
  # an event emitter binding and we want it bound to the instance
  onPacket: (packet, rinfo) =>
    for {name, metric, type} in @parsePacket packet
      for event in @events when @matchEvent event, name
        comparisons = @getMetricComparisons(event) or []
        if comparisons?.length
          allComparisonsPass = _.every comparisons, ({comparison, value}) =>
            # No support for delta comparison on packet events
            throw new Error 'delta comparison not supported for event alerts' \
              if @isDelta comparison

            @doComparison comparison, metric, value
        else
          allComparisonsPass = true

        continue unless allComparisonsPass

        # Note: the first argument to `extend` helps simulate a deep clone
        @dispatchEvent event.dispatcher, _.extend {}, event,
          {name, metric, type}

  # Extract metric comparison type and value from event properties defined
  # in configuration file.
  getMetricComparisons: (eventConfig) ->
    for key of @constructor.COMPARISONS when key of eventConfig
      comparison = key
      value = eventConfig[key]
      {comparison, value}

  # Perform comparison using comparison functions defined above
  doComparison: (comparison, eventMetric, alertValue) ->
    compareFn = @constructor.COMPARISONS[comparison.toLowerCase()]
    compareFn?(eventMetric, alertValue) ? false

  # Extracts all metrics properties that match the metrics event
  # definition in the configuration file.
  extractMatchedMetrics: (metricsEvent, metrics) ->
    {type, name, key} = metricsEvent
    subMetrics = metrics?[type]
    return unless subMetrics

    fetchMetricsProperty = (metricsObj, metricsKey) ->
      if metricsKey? and metricsKey of metricsObj
        metricsObj[metricsKey]
      else
        metricsObj

    # Extract matched metrics, careful to wildcard match name
    matchedEventMetrics = []
    if name of subMetrics
      matchedEventMetrics.push
        name: name
        metric: fetchMetricsProperty subMetrics[name], key
    else
      # Grab first event from sub metrics that
      for evtName of subMetrics when @wildcardMatch name, evtName
        matchedEventMetrics.push
          name: evtName
          metric: fetchMetricsProperty subMetrics[evtName], key

    matchedEventMetrics

  # Wraps up delta metrics computation
  extractDeltaMetrics: (event, metrics, lastMetrics) ->
    return unless lastMetrics

    currentMetrics = @extractMatchedMetrics event, metrics
    lastMetrics = @extractMatchedMetrics event, lastMetrics
    lastMetricsByName = _.indexBy lastMetrics, 'name'

    # Compute delta metrics and return in proper format
    for currentMetric in currentMetrics
      lastMetric = lastMetricsByName[currentMetric.name]?.metric
      if lastMetric?
        currentMetric.metric = currentMetric.metric - lastMetric
      else
        currentMetric.metric = 0
      currentMetric

  handleEventMetrics: (eventConfig, eventMetrics) ->
    comparisons = @getMetricComparisons eventConfig
    return unless comparisons?.length

    for {name, metric, deltaMetric} in eventMetrics
      allComparisonsPass = _.every comparisons, ({comparison, value}) =>
        compareMetric = if @isDelta comparison then deltaMetric else metric
        @doComparison comparison, compareMetric, value

      if allComparisonsPass
        # Note: the first argument to @doComparison is the actual computed
        # metric sent from StatsD, the second is the configured alert value
        eventToAlert = _.extend {}, eventConfig, {name, metric}
        @dispatchMetricsEvent eventToAlert.dispatcher, eventToAlert

  # Note: bound with fat arrow because it is passed as a function to
  # an event emitter binding and we want it bound to the instance
  onFlush: (timestamp, metrics) =>
    for event in @metrics
      # compute all metrics for use in handler
      matchedMetrics = @extractMatchedMetrics event, metrics
      deltaMetrics = @extractDeltaMetrics event, metrics, @lastMetrics

      # Join up the metrics
      deltaMetricsByName = _.indexBy deltaMetrics, 'name'
      eventMetrics = for {name, metric} in matchedMetrics
        _.extend {name, metric}, deltaMetric: deltaMetricsByName[name]?.metric

      # Perform comparisons on events and dispatch appropriately
      @handleEventMetrics event, eventMetrics

    # Store metrics for delta comparisons
    @lastMetrics = metrics
