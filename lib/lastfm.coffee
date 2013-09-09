http     = require "http"
tz       = require "timezone"
_        = require "lodash"
cache    = require "./cache"

class LastFM
  @instance: -> @_instance ?= new this
  
  API_KEY: process.env.LAST_FM_API_KEY
  USER: "fauxparse"
  
  getJSON: (method, params = {}, callback) ->
    [params, callback] = [{}, params] unless callback?
    url = "http://ws.audioscrobbler.com/2.0/?method=#{method}&api_key=#{@API_KEY}&format=json"
    for own key, value of params
      url += "&#{key}=#{escape(value)}"
    http
      .get url, (response) ->
        body = ""
        response.on "data", (chunk) -> body += chunk
        response.on "end", ->
          data = JSON.parse body
          callback false, data
      .on "error", (e) ->
        callback e
        
  refreshAlbums: (callback) =>
    @getJSON "user.gettopalbums", { user: @USER, limit: 10, period: "3month" }, (error, albums) =>
      callback error, (@sanitizeAlbum album for album in albums.topalbums.album)
        
  refreshRecent: (callback) =>
    @getJSON "user.getrecenttracks", { user: @USER, limit: 1 }, (error, tracks) =>
      callback error, @sanitizeTrack(tracks.recenttracks.track)
      
  sanitizeAlbum: (album) ->
    result =
      name:   album.name
      artist: album.artist?.name
      url:    album.url
      image:  @sanitizeImages(album.image)
  
  sanitizeTrack: (track) ->
    track = track[0] ? track
    result =
      name:   track.name
      artist: track.artist?["#text"]
      album:  track.album?["#text"]
      url:    track.url
      image:  @sanitizeImages(track.image)
      now:    track["@attr"]?.nowplaying is "true"
    
  sanitizeImages: (images) ->
    result = {}
    for img in images
      result[img.size] = img["#text"]
    result
        
  recent: (callback) ->
    cache "albums.#{@USER}", @refreshAlbums, 86400, (error, albums) =>
      cache "scrobbled.#{@USER}", @refreshRecent, 60, (error, mostRecent) =>
        callback error,
          albums: albums
          recent: mostRecent

module.exports = LastFM.instance()
