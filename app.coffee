fs = require "fs"
express = require "express"
app = express()

PORT = process.env.PORT || 5000

global.TIMEZONE = "Pacific/Auckland"

Twitter   = require "./lib/twitter"
Instagram = require "./lib/instagram"
LastFM    = require "./lib/lastfm"

app.configure ->
  app.set    "views",   "#{__dirname}/Build"
  app.engine "html",    require("ejs").renderFile
  app.use    "/assets", express.static("#{__dirname}/Build/assets")
  app.use    "/",       express.static("#{__dirname}/Build")
  app.use    express.bodyParser()

app.get "/", (request, response) ->
  response.render "index.html"
  
app.get "/tweets", (request, response) ->
  Twitter.timeline "fauxparse", (error, tweets) ->
    response.contentType "application/json;charset=utf-8"
    unless error
      response.send JSON.stringify(tweets.slice(0, 12))
    else
      response.send { error: error }, 500

app.get "/photos", (request, response) ->
  Instagram.recent (error, photos) ->
    unless error
      response.contentType "application/json;charset=utf-8"
      response.send JSON.stringify(photos)
    else
      response.send { error: error }, 500
    
app.get "/music", (request, response) ->
  LastFM.recent (error, music) ->
    unless error
      response.contentType "application/json;charset=utf-8"
      response.send JSON.stringify(music)
    else
      response.send { error: error }, 500
    
app.get "/images", (request, response) ->
  root = "#{__dirname}/Build/assets/img/design"
  fs.readdir root, (error, files) ->
    files = files.filter (f) ->
      !fs.statSync("#{root}/#{f}").isDirectory()
    response.send JSON.stringify(files)
  
app.listen PORT, ->
  console.log "Listening on #{PORT}"
