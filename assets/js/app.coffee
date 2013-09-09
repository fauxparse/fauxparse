class SlideShow
  constructor: ->
    @images = {}
    @from = $("#design .thumbnails a")
    @el = $("<div>")
      .addClass("slideshow")
      .hide()
      .appendTo("body")
    @pages = $("<div>")
      .addClass("pages")
      .appendTo(@el)
    for own key, icon of { prev: "left", next: "right" }
      $("<a>", href: "#", rel: key)
        .html("<span class=\"glyphicon glyphicon-chevron-#{icon}\"></span>")
        .appendTo(@el)
        .on("click", @[key])
    $("<a>", href: "#", rel: "close")
      .html("&times;")
      .appendTo(@el)
      .on("click", @hide)
    $(window).on "resize", @resize
    
  show: (index) ->
    if @showing
      @move index, true
    else
      @move index or 0, false
      @el.show()
      @immediately => @el.addClass "in"
      $(window).on "keyup.slideshow", @keypress
      @showing = true
      
  move: (position, animate) =>
    return if position is @position
    index = position % @from.length
    @load(index).css left: "#{position * 100}%"
    @load(index + 1).css left: "#{(position + 1) * 100}%"
    @load(index - 1).css left: "#{(position - 1) * 100}%"
    @pages.css left: "#{position * -100}%"
    @position = position
    
  prev: (e) =>
    e.preventDefault()
    @move (@position or 0) - 1
      
  next: (e) =>
    e.preventDefault()
    @move (@position or 0) + 1
      
  load: (index) =>
    @images[index] or= $("<img>")
      .attr("src", @from.eq(index).attr("href"))
      .appendTo(@pages)
      .wrap("<div class=\"loading page\" data-index=\"index\">")
      .on "load", ->
        img = $(this)
        img
          .css(marginLeft: -img.width() / 2, marginTop: -img.height() / 2)
          .parent().removeClass("loading").end()
    @images[index].parent()
    
  hide: (e) =>
    e?.preventDefault()
    @el.removeClass("in")
    @after 500, => @el.hide()
    $(window).off ".slideshow"
    @showing = false
    
  thumbnailClicked: (e) =>
    if e?.target
      e.preventDefault()
      index = @from.index($(e.target).closest("a"))
      @show index
    else
      @show()
      
  keypress: (e) =>
    console.log e
    switch e.which
      when 27
        @hide()
        e.preventDefault()
        e.stopPropagation()
        
  after: (timeout, callback) -> setTimeout callback, timeout
  
  immediately: (callback) -> @after 0, callback
  
  resize: =>
    for own _, img of @images
      img.css(marginLeft: -img.width() / 2, marginTop: -img.height() / 2)

$ ->
  $(window)
    .on "resize", ->
      $("section.full-height").css "min-height", $(this).innerHeight()
      $(this).trigger "scroll"
    .on "scroll", ->
      $("#portrait").css "top", Math.min($("#home").offset().top - $(this).scrollTop(), 0)
    .trigger "resize"
    
  $("a[href^='http:']").attr "target", "_blank"
  $("a[href^='#']").smoothScroll
    speed: 1000
    
  $.getJSON("/images")
    .done (images) ->
      container = $("#design .thumbnails")
      row = undefined
      for filename, i in images
        if i % 6 is 0
          row?.appendTo container
          row = $("<div>").addClass row
        
        div = $("<div>")
          .addClass("col-xs-2")
          .appendTo(row)
        $("<img>", src: "/assets/img/design/thumbs/#{filename}", "class": "img-responsive")
          .appendTo(div)
          .wrap("<a href=\"/assets/img/design/#{filename}\">")
      row.appendTo(container) if row.children().length
      
      slideshow = new SlideShow
      $("#design .thumbnails").on "click", "a", slideshow.thumbnailClicked
    
  escapeHTML = (text) ->
    $("<div>").text(text).html()
    
  linkifyTweet = (tweet) ->
    return escapeHTML(tweet.text) unless tweet.entities

    index_map = {}
    
    mapper = (tweet, key, callback) ->
      for entry in tweet.entities[key] or []
        index_map[entry.indices[0]] = [
          entry.indices[1]
          callback(entry, escapeHTML(tweet.text.substring(entry.indices[0], entry.indices[1])))
        ]
        
    mappers =
      urls: (entry, text) -> "<a rel=\"link\" href=\"#{escapeHTML(entry.url)}\" target=\"_blank\">#{text}</a>"
      hashtags: (entry, text) -> "<a rel=\"hashtag\" href=\"http://twitter.com/search?q=#{escape("#" + entry.text)}\" target=\"_blank\">#{text}</a>"
      user_mentions: (entry, text) -> "<a rel=\"user\" href=\"http://twitter.com/#{escape(entry.screen_name)}\" target=\"_blank\">#{text}</a>"
    
    for own key, callback of mappers
      mapper tweet, key, callback
    
    result = ""
    last_i = 0
    i = 0
    
    while i < tweet.text.length
      if ind = index_map[i]
        [end, replacement] = ind
        if i > last_i
          result += escapeHTML(tweet.text.substring(last_i, i))
        result += replacement
        i = last_i = end
      else
        i++
    if i > last_i
      result += escapeHTML(tweet.text.substring(last_i, i))
    result.replace /\n/g, "<br>"
    
  formatTweet = (tweet) ->
    li = $("<li>")
    $("<p>").html(linkifyTweet(tweet)).appendTo li
    meta = $("<small>").appendTo li
    $("<a>", href: "", text: tweet.time, target: "_blank").appendTo meta
    if tweet.retweet_count
      meta.append "<span><i class=\"glyphicon glyphicon-retweet\"></i> #{tweet.retweet_count}</span>"
    if tweet.favorite_count
      meta.append "<span><i class=\"glyphicon glyphicon-star\"></i> #{tweet.favorite_count}</span>"
    li
    
  musicMediaObject = (media, imageSize = "large") ->
    li = $("<li>", "class": "media")
      .append(
        $("<a>", href: media.url, "class": "pull-left", target: "_blank")
          .append($("<img>", src: media.image[imageSize], "class": "media-object"))
      )
      .append(
        $("<div>", "class": "media-body")
          .append($("<h5>", "class": "artist").text(media.artist))
          .append($("<h4>", "class": "name").text(media.name))
      )
    if media.album
      $(".media-body", li).append(
        $("<h5>", "class": "album").text(media.album)
      )
    li.toggleClass "now-playing", media.now
    
  $.getJSON("/tweets")
    .done (tweets) =>
      fragment = document.createDocumentFragment()
      for tweet in tweets.slice(0, 5)
        formatTweet(tweet).appendTo fragment
      $(".tweets")[0].appendChild fragment
      $(".twitter").removeClass("loading")
      
  $.getJSON("/photos")
    .done (photos) =>
      fragment = document.createDocumentFragment()
      for photo in photos.slice(0, 12)
        $("<a>", href: photo.link, target: "_blank")
          .append($("<img>", src: photo.images.thumbnail.url))
          .appendTo(fragment)
          .wrap("<li>")
      $(".photos")[0].appendChild fragment
      $(".instagram").removeClass("loading")
      
  $.getJSON("/music")
    .done (music) =>
      musicMediaObject(music.recent, "extralarge").appendTo(".lastfm .recent")
      fragment = document.createDocumentFragment()
      for album in music.albums.slice(0, 3)
        musicMediaObject(album).appendTo fragment
      $(".albums")[0].appendChild fragment
      $(".lastfm").removeClass("loading")