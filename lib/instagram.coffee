instagram = require "instagram"
tz        = require "timezone"
_         = require "lodash"
cache     = require "./cache"

class Instagram
  ID: process.env.INSTAGRAM_USER_ID
  TOKEN: process.env.INSTAGRAM_ACCESS_TOKEN
  
  @instance: -> @_instance or= new this
  
  instagram: ->
    @_instagram or= instagram.createClient(
      process.env.INSTAGRAM_CLIENT_ID,
      process.env.INSTAGRAM_CLIENT_SECRET
    )
    
  refresh: (callback) =>
    @instagram().fetch "/v1/users/#{@ID}/media/recent", { count: 12, access_token: @TOKEN }, (images, error, pagination) =>
      callback error, (@sanitize image for image in images)
      
  timezone: (args...) ->
    @_timezone or= tz(require "timezone/#{TIMEZONE}")
    @_timezone args..., TIMEZONE
      
  sanitize: (image) =>
    time = @timezone parseInt(image.created_time, 10), "%-I:%M%P %A, %B %-d, %Y"
    result =
      id:     image.id
      link:   image.link
      likes:  image.likes.count
      images: image.images
      time:   time
      text:   image.caption?.text
  
  recent: (callback) ->
    cache "instagram.#{@ID}", @refresh, 900, callback
  
module.exports = Instagram.instance()
