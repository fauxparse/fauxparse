Redis = require("redis")

class Cache
  redis: ->
    unless @_redis
      if process.env.REDISTOGO_URL
        url   = require("url").parse process.env.REDISTOGO_URL
        @_redis = Redis.createClient url.port, url.hostname
        @_redis.auth url.auth.split(":")[1]
      else
        @_redis = Redis.createClient()
    @_redis
    
  set: (key, value, expiry) ->
    @redis().set key, JSON.stringify(value)
    @redis().expire key, expiry if expiry?
    
  get: (key, callback) ->
    @redis().get key, (error, value) ->
      value = JSON.parse value if value and !error
      callback error, value
      
  cache: (key, value_or_callback, expiry, callback) =>
    [callback, expiry] = [expiry, null] unless callback?
    @get key, (error, value) =>
      if error
        callback error, value
      else if value
        callback false, value
      else
        if typeof value_or_callback is "function"
          value_or_callback (error, value) =>
            if error
              callback error
            else
              @set key, value, expiry
              callback false, value
        else
          @set key, value_or_callback, expiry
          callback false, value_or_callback
  
  @instance: -> @_instance or= new this
  
module.exports = Cache.instance().cache