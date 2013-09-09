(function() {
  var SlideShow,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty;

  SlideShow = (function() {
    function SlideShow() {
      this.keypress = __bind(this.keypress, this);
      this.thumbnailClicked = __bind(this.thumbnailClicked, this);
      this.hide = __bind(this.hide, this);
      this.load = __bind(this.load, this);
      this.next = __bind(this.next, this);
      this.prev = __bind(this.prev, this);
      this.move = __bind(this.move, this);
      var icon, key, _ref;
      this.images = {};
      this.from = $("#design .thumbnails a");
      this.el = $("<div>").addClass("slideshow").hide().appendTo("body");
      this.pages = $("<div>").addClass("pages").appendTo(this.el);
      _ref = {
        prev: "left",
        next: "right"
      };
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        icon = _ref[key];
        $("<a>", {
          href: "#",
          rel: key
        }).html("<span class=\"glyphicon glyphicon-chevron-" + icon + "\"></span>").appendTo(this.el).on("click", this[key]);
      }
      $("<a>", {
        href: "#",
        rel: "close"
      }).html("&times;").appendTo(this.el).on("click", this.hide);
    }

    SlideShow.prototype.show = function(index) {
      var _this = this;
      if (this.showing) {
        return this.move(index, true);
      } else {
        this.move(index || 0, false);
        this.el.show();
        this.immediately(function() {
          return _this.el.addClass("in");
        });
        $(window).on("keyup.slideshow", this.keypress);
        return this.showing = true;
      }
    };

    SlideShow.prototype.move = function(position, animate) {
      var index;
      if (position === this.position) {
        return;
      }
      index = position % this.from.length;
      this.load(index).css({
        left: "" + (position * 100) + "%"
      });
      this.load(index + 1).css({
        left: "" + ((position + 1) * 100) + "%"
      });
      this.load(index - 1).css({
        left: "" + ((position - 1) * 100) + "%"
      });
      this.pages.css({
        left: "" + (position * -100) + "%"
      });
      return this.position = position;
    };

    SlideShow.prototype.prev = function(e) {
      e.preventDefault();
      return this.move((this.position || 0) - 1);
    };

    SlideShow.prototype.next = function(e) {
      e.preventDefault();
      return this.move((this.position || 0) + 1);
    };

    SlideShow.prototype.load = function(index) {
      var _base;
      (_base = this.images)[index] || (_base[index] = $("<img>").attr("src", this.from.eq(index).attr("href")).appendTo(this.pages).wrap("<div class=\"loading page\" data-index=\"index\">").hide().on("load", function() {
        var img;
        img = $(this);
        return img.css({
          marginLeft: -img.width() / 2,
          marginTop: -img.height() / 2
        }).fadeIn().parent().removeClass("loading").end();
      }));
      return this.images[index].parent();
    };

    SlideShow.prototype.hide = function(e) {
      var _this = this;
      if (e != null) {
        e.preventDefault();
      }
      this.el.removeClass("in");
      this.after(500, function() {
        return _this.el.hide();
      });
      $(window).off(".slideshow");
      return this.showing = false;
    };

    SlideShow.prototype.thumbnailClicked = function(e) {
      var index;
      if (e != null ? e.target : void 0) {
        e.preventDefault();
        console.log(this.from.index($(e.target).closest("a")));
        index = this.from.index($(e.target).closest("a"));
        return this.show(index);
      } else {
        return this.show();
      }
    };

    SlideShow.prototype.keypress = function(e) {
      console.log(e);
      switch (e.which) {
        case 27:
          this.hide();
          e.preventDefault();
          return e.stopPropagation();
      }
    };

    SlideShow.prototype.after = function(timeout, callback) {
      return setTimeout(callback, timeout);
    };

    SlideShow.prototype.immediately = function(callback) {
      return this.after(0, callback);
    };

    return SlideShow;

  })();

  $(function() {
    var escapeHTML, formatTweet, linkifyTweet, musicMediaObject,
      _this = this;
    $(window).on("resize", function() {
      $("section.full-height").css("min-height", $(this).innerHeight());
      return $(this).trigger("scroll");
    }).on("scroll", function() {
      return $("#portrait").css("top", Math.min($("#home").offset().top - $(this).scrollTop(), 0));
    }).trigger("resize");
    $("a[href^='http:']").attr("target", "_blank");
    $("a[href^='#']").smoothScroll({
      speed: 1000
    });
    $.getJSON("/images").done(function(images) {
      var container, div, filename, i, row, slideshow, _i, _len;
      container = $("#design .thumbnails");
      row = void 0;
      for (i = _i = 0, _len = images.length; _i < _len; i = ++_i) {
        filename = images[i];
        if (i % 6 === 0) {
          if (row != null) {
            row.appendTo(container);
          }
          row = $("<div>").addClass(row);
        }
        div = $("<div>").addClass("col-xs-2").appendTo(row);
        $("<img>", {
          src: "/assets/img/design/thumbs/" + filename,
          "class": "img-responsive"
        }).appendTo(div).wrap("<a href=\"/assets/img/design/" + filename + "\">");
      }
      if (row.children().length) {
        row.appendTo(container);
      }
      slideshow = new SlideShow;
      return $("#design .thumbnails").on("click", "a", slideshow.thumbnailClicked);
    });
    escapeHTML = function(text) {
      return $("<div>").text(text).html();
    };
    linkifyTweet = function(tweet) {
      var callback, end, i, ind, index_map, key, last_i, mapper, mappers, replacement, result;
      if (!tweet.entities) {
        return escapeHTML(tweet.text);
      }
      index_map = {};
      mapper = function(tweet, key, callback) {
        var entry, _i, _len, _ref, _results;
        _ref = tweet.entities[key] || [];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          entry = _ref[_i];
          _results.push(index_map[entry.indices[0]] = [entry.indices[1], callback(entry, escapeHTML(tweet.text.substring(entry.indices[0], entry.indices[1])))]);
        }
        return _results;
      };
      mappers = {
        urls: function(entry, text) {
          return "<a rel=\"link\" href=\"" + (escapeHTML(entry.url)) + "\" target=\"_blank\">" + text + "</a>";
        },
        hashtags: function(entry, text) {
          return "<a rel=\"hashtag\" href=\"http://twitter.com/search?q=" + (escape("#" + entry.text)) + "\" target=\"_blank\">" + text + "</a>";
        },
        user_mentions: function(entry, text) {
          return "<a rel=\"user\" href=\"http://twitter.com/" + (escape(entry.screen_name)) + "\" target=\"_blank\">" + text + "</a>";
        }
      };
      for (key in mappers) {
        if (!__hasProp.call(mappers, key)) continue;
        callback = mappers[key];
        mapper(tweet, key, callback);
      }
      result = "";
      last_i = 0;
      i = 0;
      while (i < tweet.text.length) {
        if (ind = index_map[i]) {
          end = ind[0], replacement = ind[1];
          if (i > last_i) {
            result += escapeHTML(tweet.text.substring(last_i, i));
          }
          result += replacement;
          i = last_i = end;
        } else {
          i++;
        }
      }
      if (i > last_i) {
        result += escapeHTML(tweet.text.substring(last_i, i));
      }
      return result.replace(/\n/g, "<br>");
    };
    formatTweet = function(tweet) {
      var li, meta;
      li = $("<li>");
      $("<p>").html(linkifyTweet(tweet)).appendTo(li);
      meta = $("<small>").appendTo(li);
      $("<a>", {
        href: "",
        text: tweet.time,
        target: "_blank"
      }).appendTo(meta);
      if (tweet.retweet_count) {
        meta.append("<span><i class=\"glyphicon glyphicon-retweet\"></i> " + tweet.retweet_count + "</span>");
      }
      if (tweet.favorite_count) {
        meta.append("<span><i class=\"glyphicon glyphicon-star\"></i> " + tweet.favorite_count + "</span>");
      }
      return li;
    };
    musicMediaObject = function(media, imageSize) {
      var li;
      if (imageSize == null) {
        imageSize = "large";
      }
      li = $("<li>", {
        "class": "media"
      }).append($("<a>", {
        href: media.url,
        "class": "pull-left",
        target: "_blank"
      }).append($("<img>", {
        src: media.image[imageSize],
        "class": "media-object"
      }))).append($("<div>", {
        "class": "media-body"
      }).append($("<h5>", {
        "class": "artist"
      }).text(media.artist)).append($("<h4>", {
        "class": "name"
      }).text(media.name)));
      if (media.album) {
        $(".media-body", li).append($("<h5>", {
          "class": "album"
        }).text(media.album));
      }
      return li.toggleClass("now-playing", media.now);
    };
    $.getJSON("/tweets").done(function(tweets) {
      var fragment, tweet, _i, _len, _ref;
      fragment = document.createDocumentFragment();
      _ref = tweets.slice(0, 5);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        tweet = _ref[_i];
        formatTweet(tweet).appendTo(fragment);
      }
      $(".tweets")[0].appendChild(fragment);
      return $(".twitter").removeClass("loading");
    });
    $.getJSON("/photos").done(function(photos) {
      var fragment, photo, _i, _len, _ref;
      fragment = document.createDocumentFragment();
      _ref = photos.slice(0, 12);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        photo = _ref[_i];
        $("<a>", {
          href: photo.link,
          target: "_blank"
        }).append($("<img>", {
          src: photo.images.thumbnail.url
        })).appendTo(fragment).wrap("<li>");
      }
      $(".photos")[0].appendChild(fragment);
      return $(".instagram").removeClass("loading");
    });
    return $.getJSON("/music").done(function(music) {
      var album, fragment, _i, _len, _ref;
      musicMediaObject(music.recent, "extralarge").appendTo(".lastfm .recent");
      fragment = document.createDocumentFragment();
      _ref = music.albums.slice(0, 3);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        album = _ref[_i];
        musicMediaObject(album).appendTo(fragment);
      }
      $(".albums")[0].appendChild(fragment);
      return $(".lastfm").removeClass("loading");
    });
  });

}).call(this);
