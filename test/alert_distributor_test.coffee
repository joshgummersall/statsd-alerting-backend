AlertDistributor = require '../src/alert_distributor'
should = require 'should'
sinon = require 'sinon'

describe 'AlertDistributor', ->
  beforeEach ->
    @instance = new AlertDistributor
      slack: {}
      pagerduty: key: ''
      log: {}

  describe 'parsePacket', ->
    beforeEach ->
      @packet = (packetString) ->
        new Buffer packetString

      @parse = (packetString) =>
        @instance.parsePacket @packet packetString

      @parseOne = (packetString) =>
        [first] = @parse packetString
        first

    it 'should parse a count packet', ->
      {name, metric, type} = @parseOne 'some.event.here:10|c'
      name.should.eql 'some.event.here'
      metric.should.eql 10
      type.should.eql 'c'

    it 'should parse a timer packet', ->
      {name, metric, type} = @parseOne 'another.event.here:320|ms'
      name.should.eql 'another.event.here'
      metric.should.eql 320
      type.should.eql 'ms'

    it 'should parse several packets', ->
      events = @parse [
        'some.event.here:10|c'
        'another.event.here:320|ms'
      ].join '\n'

      events.length.should.eql 2
      for event in events
        event[key].should.be.ok for key in ['name', 'metric', 'type']

  describe 'matchEvent', ->
    beforeEach ->
      @buildEvent = (name) ->
        {name}

      @match = (eventName, matchName) =>
        @instance.matchEvent @buildEvent(eventName), matchName

    it 'should match a name exactly', ->
      @match('some.event.here', 'some.event.here').should.be.ok

    it 'should match an event with a wildcard', ->
      @match('some.*', 'some.event.here').should.be.ok

    it 'should match a second level wildcard', ->
      @match('some.event.*', 'some.event.bad').should.be.ok
      @match('some.event.*', 'some.event.good').should.be.ok

    it 'should not match an event', ->
      @match('should.not.match', 'should.match').should.not.be.ok

  describe 'doComparison', ->
    beforeEach ->
      @compare = (comparison, value, metric) =>
        @instance.doComparison comparison, value, metric

    it 'should do a >= comparison', ->
      @compare('gte', 11, 10).should.be.ok
      @compare('gte', 10, 10).should.be.ok
      @compare('gte', 9, 10).should.not.be.ok

    it 'should do a > comparison', ->
      @compare('gt', 11, 10).should.be.ok
      @compare('gt', 10, 10).should.not.be.ok
      @compare('gt', 9, 10).should.not.be.ok

    it 'should do a <= comparison', ->
      @compare('lte', 11, 10).should.not.be.ok
      @compare('lte', 10, 10).should.be.ok
      @compare('lte', 9, 10).should.be.ok

    it 'should do a < comparison', ->
      @compare('lt', 11, 10).should.not.be.ok
      @compare('lt', 10, 10).should.not.be.ok
      @compare('lt', 9, 10).should.be.ok

  describe 'dispatchEvent', ->
    beforeEach ->
      @sandbox = sinon.sandbox.create()
      for type of @instance.dispatchers
        this["#{type}Mock"] = @sandbox.mock @instance.dispatchers[type]

      @expects = (types...) ->
        this["#{type}Mock"].expects('sendEvent').once() for type in types

      @dispatch = (types...) =>
        @instance.dispatchEvent(type, {}) for type in types

      @verify = (types...) =>
        this["#{type}Mock"].verify() for type in types

    afterEach ->
      @sandbox.restore()

    it 'should dispatch an event to all types', ->
      for type of @instance.dispatchers
        @expects type
        @dispatch type
        @verify type
