(function() {
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  $(function() {
    var Apple, FormatNumberLength, Player, Sprite, State, apple, c, canvas, counter, draw, getCanvasLocalCoordinates, getTouchEvent, hitTest, info, isAndroid, isIPhone, isSmartPhone, lastTouchPoint, onTouchEnd, onTouchMove, onTouchStart, player, settings, setupCanvasSize, showBonus, splash;
    window.top.scrollTo(0, 0);
    Sprite = (function() {
      function Sprite(x, y, src, w, h) {
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.image = new Image;
        this.image.src = "assets/images/" + src;
      }
      Sprite.prototype.draw = function(c) {
        if (this.w != null) {
          return c.drawImage(this.image, this.x, this.y, this.w, this.h);
        } else {
          return c.drawImage(this.image, this.x, this.y);
        }
      };
      return Sprite;
    })();
    Player = (function() {
      __extends(Player, Sprite);
      function Player() {
        var initScore;
        Player.__super__.constructor.call(this, 50, 50, "player.png", 30, 30);
        initScore = parseInt(localStorage.getItem("ringo-score"));
        if (isNaN(initScore)) {
          initScore = 0;
          localStorage.setItem("ringo-score", 0);
        }
        this.score = initScore;
      }
      Player.prototype.moveDelta = function(dx, dy) {
        this.x += dx;
        this.y += dy;
        if (player.x < 0) {
          player.x = 0;
        }
        if (player.y < 0) {
          player.y = 0;
        }
        if (player.x > canvas.width - 15) {
          player.x = canvas.width - 15;
        }
        if (player.y > canvas.height - 30) {
          return player.y = canvas.height - 30;
        }
      };
      return Player;
    })();
    Apple = (function() {
      __extends(Apple, Sprite);
      function Apple() {
        var src;
        Apple.__super__.constructor.call(this, 0, 0, "apple.png", 30, 30);
        this.isBonus = false;
        this.audio = document.createElement('audio');
        src = document.createElement('source');
        src.setAttribute("src", "assets/sounds/se1.wav");
        src.setAttribute("type", "audio/wav");
        this.audio.appendChild(src);
        this.bonus = document.createElement('audio');
        src = document.createElement('source');
        src.setAttribute("src", "assets/sounds/se2.wav");
        src.setAttribute("type", "audio/wav");
        this.bonus.appendChild(src);
      }
      Apple.prototype.generate = function(canvas) {
        var r;
        r = Math.random() * 100;
        if (r <= 10) {
          this.w = 50;
          this.h = 50;
          this.isBonus = true;
        } else {
          this.w = 30;
          this.h = 30;
          this.isBonus = false;
        }
        this.x = Math.floor(Math.random() * (canvas.width - 15));
        return this.y = Math.floor(Math.random() * (canvas.height - 30));
      };
      Apple.prototype.hitTest = function(player) {
        var dd, showBonus;
        dd = this.isBonus ? 25 : 15;
        if (player.x > this.x - dd && player.x < this.x + dd && player.y > this.y - dd && player.y < this.y + dd) {
          player.score += this.isBonus ? 10 : 1;
          if (player.score % 10 === 0) {
            showBonus = true;
            draw();
          }
          if (this.isBonus) {
            this.bonus.play();
          } else {
            this.audio.play();
          }
          localStorage.setItem("ringo-score", player.score);
          return this.generate(canvas);
        }
      };
      return Apple;
    })();
    FormatNumberLength = function(num, length) {
      var r;
      r = "" + num;
      while (r.length < length) {
        r = "0" + r;
      }
      return r;
    };
    setupCanvasSize = function() {
      canvas.width = document.body.clientWidth;
      canvas.height = document.body.clientHeight;
      if (State._current !== State.INIT) {
        draw();
      }
      return true;
    };
    isIPhone = (new RegExp("iPhone", "i")).test(navigator.userAgent);
    isAndroid = (new RegExp("Android", "i")).test(navigator.userAgent);
    isSmartPhone = isAndroid || isIPhone;
    lastTouchPoint = {
      x: 50,
      y: 50
    };
    getCanvasLocalCoordinates = function(pageX, pageY) {
      var position;
      position = $("#canvas").offset();
      return {
        x: pageX - position.left,
        y: pageY - position.top
      };
    };
    hitTest = function(elem, x0, x1, y0, y1) {
      return elem.y > y0 && elem.y < y1 && elem.x > x0 && elem.x < x1;
    };
    getTouchEvent = function(event) {
      if (isSmartPhone) {
        return window.event.targetTouches[0];
      } else {
        return event;
      }
    };
    onTouchStart = function(event) {
      var localPosition, touch;
      touch = getTouchEvent(event);
      event.preventDefault();
      localPosition = getCanvasLocalCoordinates(touch.pageX, touch.pageY);
      if (State._current === State.PLAYING) {
        if (hitTest(localPosition, canvas.width - 30, canvas.width, 0, 30)) {
          State._current = State.SETTINGS;
          draw();
          return;
        }
      } else {
        if (hitTest(localPosition, canvas.width / 2 + 120, canvas.width / 2 + 150, canvas.height / 2 - 240, canvas.height / 2 - 215)) {
          State._current = State.PLAYING;
          draw();
          return;
        }
        if (hitTest(localPosition, canvas.width / 2 + 70, canvas.width / 2 + 140, canvas.height / 2 + 130, canvas.height / 2 + 165)) {
          if (confirm("Would you like to reset your score?")) {
            player.score = 0;
            localStorage.setItem("ringo-score", 0);
            draw();
          }
          return;
        }
        if (hitTest(localPosition, canvas.width / 2 - 125, canvas.width / 2 + 125, canvas.height / 2 + 175, canvas.height / 2 + 225)) {
          if (confirm("Would you like to reset your visit m7kenji.com?")) {
            window.location = "http://m7kenji.com";
          }
          return;
        }
        if (hitTest(localPosition, canvas.width / 2 + 70, canvas.width / 2 + 110, canvas.height / 2 + 50, canvas.height / 2 + 90)) {
          if (confirm("Would you like to tweet your score?")) {
            window.location = "http://twitter.com/home?status=" + escape("I have collected " + player.score + " apples so far. http://zaki.asia/ringo Get the iPhone App: http://t.co/9OK31BL #ringo_html");
          }
          return;
        }
      }
      lastTouchPoint = {
        x: localPosition.x,
        y: localPosition.y
      };
      $("#canvas").bind("touchmove", onTouchMove);
      return $("#canvas").bind("mousemove", onTouchMove);
    };
    onTouchMove = function(event) {
      var dx, dy, localPosition, touch;
      touch = getTouchEvent(event);
      localPosition = getCanvasLocalCoordinates(touch.pageX, touch.pageY);
      dx = localPosition.x - lastTouchPoint.x;
      dy = localPosition.y - lastTouchPoint.y;
      lastTouchPoint = {
        x: localPosition.x,
        y: localPosition.y
      };
      player.moveDelta(dx / 1.2, dy / 1.2);
      apple.hitTest(player);
      return setTimeout(draw, 1);
    };
    onTouchEnd = function(event) {
      $("#canvas").unbind("touchmove", onTouchMove);
      return $("#canvas").unbind("mousemove", onTouchMove);
    };
    State = {
      _current: 0,
      INIT: 0,
      INTRO: 1,
      PLAYING: 2,
      SETTINGS: 3
    };
    canvas = document.getElementById('canvas');
    c = canvas.getContext('2d');
    canvas.width = document.body.clientWidth;
    canvas.height = document.body.clientHeight;
    showBonus = false;
    splash = new Sprite(canvas.width / 2 - 160, canvas.height / 2 - 240, "splash.png");
    splash.image.onload = function() {
      return splash.draw(c);
    };
    counter = new Sprite(3, 3, "counter.png");
    info = new Sprite(canvas.width - 23, 2, "info.png");
    player = new Player;
    apple = new Apple;
    apple.generate(canvas);
    settings = new Sprite(canvas.width / 2 - 160, canvas.height / 2 - 240, "settings.png");
    draw = function() {
      var mt, phrase, xcoord;
      c.fillStyle = '#000000';
      c.fillRect(0, 0, canvas.width, canvas.height);
      if (State._current === State.INTRO) {
        splash.draw(c);
        return setTimeout(function() {
          State._current = State.PLAYING;
          return draw();
        }, 2000);
      } else if (State._current === State.PLAYING) {
        phrase = "X" + FormatNumberLength(player.score, 4);
        c.font = 'bold 16px Helvetica, sans-serif';
        c.fillStyle = '#FFFFFF';
        c.fillText(phrase, 20, 16);
        counter.draw(c);
        info.draw(c);
        apple.draw(c);
        player.draw(c);
        if (showBonus) {
          c.font = 'bold 32px Helvetica, sans-serif';
          c.fillStyle = '#FFFFFF';
          mt = c.measureText(phrase);
          xcoord = (canvas.width / 2) - (mt.width / 2);
          c.fillText(phrase, xcoord, canvas.height / 2 - 16);
          return setTimeout(function() {
            showBonus = false;
            return draw;
          }, 500);
        }
      } else if (State._current === State.SETTINGS) {
        settings.draw(c);
        phrase = player.score;
        c.font = 'bold 32px Helvetica, sans-serif';
        c.fillStyle = '#FFFFFF';
        mt = c.measureText(phrase);
        return c.fillText(phrase, canvas.width / 2 - mt.width / 2, canvas.height / 2 + 125);
      }
    };
    $("#canvas").bind("touchstart", onTouchStart);
    $("#canvas").bind("mousedown", onTouchStart);
    $("#canvas").bind("touchend", onTouchEnd);
    $("#canvas").bind("mouseup", onTouchEnd);
    window.onorientationchange = function() {
      setupCanvasSize();
      return apple.generate(canvas);
    };
    setupCanvasSize();
    State._current = State.INTRO;
    return draw();
  });
}).call(this);
