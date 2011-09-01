$(document).ready(function() {
  window.top.scrollTo(0, 0);
  //{{{ - Utility Functions
  function FormatNumberLength(num, length) {
    var r = "" + num;
    while (r.length < length) {
      r = "0" + r;
    }
    return r;
  }

  var generateApple = function()
  {
    apple.x = Math.floor(Math.random()*(canvas.width - 15));
    apple.y = Math.floor(Math.random()*(canvas.height- 30));
  }

  var setupCanvasSize = function()
  {
    canvas.width = document.body.clientWidth;
    canvas.height = document.body.clientHeight;
    if (State._current != State.INIT)
      draw();
    return (true);
  }
  //}}}

  //{{{ - Touch related event handler
  var lastTouchPoint = {x: 50, y: 50};
  var isIPhone = (new RegExp( "iPhone", "i" )).test( navigator.userAgent);
  var getCanvasLocalCoordinates = function( pageX, pageY )
  {
    var position = $("#canvas").offset();
    return({ x: (pageX - position.left), y: (pageY - position.top)});
  };

  var getTouchEvent = function( event ){ return( isIPhone ?  window.event.targetTouches[ 0 ] : event); };

  var onTouchStart = function( event ){
    var touch = getTouchEvent( event );
    if( navigator.userAgent.match(/Android/i) ) { touch.preventDefault(); }
    var localPosition = getCanvasLocalCoordinates( touch.pageX, touch.pageY);

    if (localPosition.y > 0 && localPosition.y < 30 &&
        localPosition.x > canvas.width - 30 && localPosition.x < canvas.width)
    {
      if (confirm("Would you like to send a tweet with your score?"))
      {
        window.location = "http://twitter.com/home?status=" + escape("I have collected "+player.score+" apples so far. http://zaki.asia/ringo Get the iPhone App: http://t.co/9OK31BL #ringo_html");
      }
    }


    lastTouchPoint = { x: localPosition.x, y: localPosition.y };
    $("#canvas").bind( ("touchmove"), onTouchMove);
    $("#canvas").bind( ("mousemove"), onTouchMove);
    return (false);
  };

  var onTouchMove = function( event ){
    var touch = getTouchEvent( event );
    var localPosition = getCanvasLocalCoordinates( touch.pageX, touch.pageY);

    var dx = localPosition.x - lastTouchPoint.x , dy = localPosition.y - lastTouchPoint.y;
    lastTouchPoint = { x: localPosition.x, y: localPosition.y };
    player.x += dx / 1.2;
    player.y += dy / 1.2;
    if (player.x < 0)
      player.x = 0;
    if (player.y < 0)
      player.y = 0;
    if (player.x > canvas.width - 15)
      player.x = canvas.width - 15;
    if (player.y > canvas.height - 30)
      player.y = canvas.height - 30;
    setTimeout(draw, 1);

    if (player.x > apple.x - 15 && player.x < apple.x + 15 &&
        player.y > apple.y - 15 && player.y < apple.y + 15)
    {
      player.score += 1;
      if (player.score % 10 == 0)
      {
        showBonus = true;
        draw();
      }
      audio.play();
      localStorage.setItem("ringo-score", player.score);
      generateApple();

    }

  };

  var onTouchEnd = function (event) {
    $("#canvas").unbind( ("touchmove"), onTouchMove);
    $("#canvas").unbind( ("mousemove"), onTouchMove);
  }
  //}}}

  //{{{ - Game Variables
  var State = { _current: 0, INIT: 0, INTRO: 1, PLAYING: 2};
  var canvas = document.getElementById('canvas');
  var c = canvas.getContext('2d');
  canvas.width = document.body.clientWidth;
  canvas.height = document.body.clientHeight;

  var showBonus = false;

  // Counter
  var counter = new Image();
  counter.src = "counter.png";

  // Counter
  var twitter = new Image();
  twitter.src = "twitter.png";

  // Player
  var initScore = parseInt(localStorage.getItem("ringo-score"));
  if (isNaN(initScore))
  {
    initScore = 0;
    localStorage.setItem("ringo-score", 0);
  }
  var player = {x: 50, y: 50, score: initScore, image: new Image()};
  player.image.src = "player.png";

  // Apple
  var apple = {x: 0, y: 0, score: 0, image: new Image()};
  apple.image.src = "apple.png";
  generateApple();

  var splash = new Image();
  splash.src = "splash.png";
  splash.onload = function() {
    c.drawImage( splash, canvas.width / 2 - 160, canvas.height / 2 - 240);
  }

  // Sound
  var audio = document.createElement('audio');
  var src = document.createElement('source');
  src.setAttribute("src", "se1.wav");
  src.setAttribute("type", "audio/wav");
  audio.appendChild(src);
  //}}}

  //{{{ - Draw
  function draw () {

    if (State._current == State.INTRO)
    {
      c.fillStyle = '#000000';
      c.fillRect(0, 0, canvas.width, canvas.height);
      c.drawImage(splash, canvas.width / 2 - 160, canvas.height / 2 - 240);
      setTimeout(function () { State._current = State.PLAYING; draw(); }, 2000);
    }
    else if (State._current == State.PLAYING)
    {
      c.fillStyle = '#000000';
      c.fillRect(0, 0, canvas.width, canvas.height);

      // Add counter
      var phrase = "X" + FormatNumberLength(player.score, 4);
      c.font = 'bold 16px Helvetica, sans-serif';
      c.fillStyle = '#FFFFFF';
      c.fillText (phrase, 20, 16);
      c.drawImage(counter, 3, 3);
      c.drawImage(twitter, canvas.width - 30, 3, 30, 30);

      c.drawImage(apple.image, apple.x, apple.y, 30, 30);
      c.drawImage(player.image, player.x, player.y, 30, 30);

      if (showBonus)
      {
        c.font = 'bold 32px Helvetica, sans-serif';
        c.fillStyle = '#FFFFFF';
        var mt = c.measureText(phrase);
        var xcoord = (canvas.width / 2) - (mt.width / 2);
        c.fillText (phrase, xcoord, canvas.height / 2 - 16);
        setTimeout(function() { showBonus = false; draw();}, 500);
      }
    }
  }
  //}}}

  $("#canvas").bind( ("touchstart"), onTouchStart);
  $("#canvas").bind( ("mousedown"), onTouchStart);
  $("#canvas").bind( ("touchend"), onTouchEnd);
  $("#canvas").bind( ("mouseup"), onTouchEnd);

  window.onorientationchange = setupCanvasSize;

  setupCanvasSize();

  State._current = State.INTRO;
  draw();
});

