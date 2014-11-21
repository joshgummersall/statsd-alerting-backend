Dispatchers =
  email: require './email'
  log: require './log'
  slack: require './slack'

exports.build = (event, config) ->
  {alert} = event
  throw new Error "Unsupported type #{alert}" unless alert of Dispatchers
  new Dispatchers[alert] event, config
