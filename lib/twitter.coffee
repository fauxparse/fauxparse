nTwitter = require "ntwitter"
tz       = require "timezone"
_        = require "lodash"
cache    = require "./cache"

class Twitter
  @instance: -> @_instance or= new this
  
  api: ->
    @_api or= new nTwitter
      consumer_key:        process.env.TWITTER_CONSUMER_KEY
      consumer_secret:     process.env.TWITTER_CONSUMER_SECRET
      access_token_key:    process.env.TWITTER_ACCESS_TOKEN
      access_token_secret: process.env.TWITTER_ACCESS_SECRET
      
  refresh: (screen_name, callback) =>
    options =
      include_entities: true
      screen_name:      "fauxparse"
      count:            50
      exclude_replies:  true
      include_rts:      false
    @api().get "/statuses/user_timeline.json", options, (error, data) =>
      data = (@sanitize tweet for tweet in data) unless error
      callback error, data
      
  timeline: (screen_name, callback) ->
    refresh = _.partial @refresh, screen_name
    cache "tweets.fauxparse", refresh, 900, (error, data) =>
      callback error, data
  
  timezone: (args...) ->
    @_timezone or= tz(require "timezone/#{TIMEZONE}")
    @_timezone args..., TIMEZONE
  
  sanitize: (tweet) ->
    time = @timezone Date.parse(tweet.created_at), "%-I:%M%P %A, %B %-d, %Y"
    result =
      id:             tweet.id_str
      user:           tweet.user.screen_name
      time:           time
      text:           tweet.text
      entities:       tweet.entities
      favorite_count: tweet.favorite_count
      retweet_count:  tweet.retweet_count
      
module.exports = Twitter.instance()
