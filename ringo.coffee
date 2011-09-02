$ ->
  window.top.scrollTo 0, 0

  #{{{ - Classes
  class Sprite
    constructor: (@x, @y, src) ->
      @image = new Image
      @image.src = "assets/images/" + src

    setSize: (@w, @h) ->

    draw: (c) ->
      if @w?
        c.drawImage @image, @x, @y, @w, @h
      else
        c.drawImage @image, @x, @y

  class Player extends Sprite
    constructor: () ->
      super 50, 50, "player.png"
      initScore = parseInt(localStorage.getItem("ringo-score"))
      if isNaN(initScore)
        initScore = 0
        localStorage.setItem "ringo-score", 0
      @score = initScore

    moveDelta: (dx, dy) ->
      @x += dx
      @y += dy
      player.x = 0 if (player.x < 0)
      player.y = 0 if (player.y < 0)
      player.x = canvas.width - 15 if (player.x > canvas.width - 15)
      player.y = canvas.height - 30 if (player.y > canvas.height - 30)

  class Apple extends Sprite
    constructor: () ->
      super 0, 0, "apple.png"
      @isBonus = false
      @audio = document.createElement('audio')
      src = document.createElement('source')
      src.setAttribute("src", "assets/sounds/se1.wav")
      src.setAttribute("type", "audio/wav")
      @audio.appendChild(src)
      @bonus = document.createElement('audio')
      src = document.createElement('source')
      src.setAttribute("src", "assets/sounds/se2.wav")
      src.setAttribute("type", "audio/wav")
      @bonus.appendChild(src)

    generate: (canvas) ->
      r = Math.random()*100
      if r <= 10
        @w = 50
        @h = 50
        @isBonus = true
      else
        @w = 30
        @h = 30
        @isBonus = false
      @x = Math.floor(Math.random()*(canvas.width - 15))
      @y = Math.floor(Math.random()*(canvas.height- 30))

    hitTest: (player) ->
      dd = if @isBonus then 25 else 15
      if (player.x > @x - dd && player.x < @x + dd && player.y > @y - dd && player.y < @y + dd)
        player.score += if @isBonus then 10 else 1
        if (player.score % 10 == 0)
          showBonus = true
          draw()
        if @isBonus
          @bonus.play()
        else
          @audio.play()
        localStorage.setItem("ringo-score", player.score)
        this.generate canvas
  #}}}

  #{{{ - Utility Functions
  FormatNumberLength = (num, length) ->
    r = "" + num
    while r.length < length
      r = "0" + r
    r

  setupCanvasSize = () ->
    canvas.width = document.body.clientWidth
    canvas.height = document.body.clientHeight
    draw() if State._current != State.INIT
    true

  isIPhone = (new RegExp("iPhone", "i")).test navigator.userAgent
  isAndroid= (new RegExp("Android", "i")).test navigator.userAgent
  isSmartPhone = isAndroid || isIPhone
  #}}}

  #{{{ - Touch related event handlers
  lastTouchPoint = {x: 50, y: 50}
  getCanvasLocalCoordinates = (pageX, pageY) ->
    position = $("#canvas").offset()
    {
      x: (pageX - position.left)
      y: (pageY - position.top)
    }

  hitTest = (elem, x0, x1, y0, y1) ->
    elem.y > y0 && elem.y < y1 && elem.x > x0 && elem.x < x1

  getTouchEvent = (event) ->
    #if isIPhone then window.event.targetTouches[0] else event
    if isSmartPhone then window.event.targetTouches[0] else event

  onTouchStart = (event) ->
    touch = getTouchEvent(event)
    event.preventDefault()
    localPosition = getCanvasLocalCoordinates(touch.pageX, touch.pageY)

    if hitTest(localPosition, canvas.width - 30, canvas.width, 0, 30)
      if (confirm("Would you like to send a tweet with your score?"))
        window.location = "http://twitter.com/home?status=" + escape("I have collected "+player.score+" apples so far. http://zaki.asia/ringo Get the iPhone App: http://t.co/9OK31BL #ringo_html")
      return

    if hitTest(localPosition, 75, 135, 0, 20)
      if (confirm("Would you like to reset your score?"))
       player.score = 0
       localStorage.setItem "ringo-score", 0
       draw()
      return

    lastTouchPoint = { x: localPosition.x, y: localPosition.y }
    $("#canvas").bind(("touchmove"), onTouchMove)
    $("#canvas").bind(("mousemove"), onTouchMove)

  onTouchMove = (event) ->
    touch = getTouchEvent(event)
    localPosition = getCanvasLocalCoordinates(touch.pageX, touch.pageY)

    dx = localPosition.x - lastTouchPoint.x
    dy = localPosition.y - lastTouchPoint.y
    lastTouchPoint = { x: localPosition.x, y: localPosition.y }
    player.moveDelta dx/1.2, dy/1.2
    apple.hitTest player

    setTimeout(draw, 1)

  onTouchEnd = (event) ->
    $("#canvas").unbind("touchmove", onTouchMove)
    $("#canvas").unbind("mousemove", onTouchMove)
  #}}}

  #{{{ - Game Variables
  State = { _current: 0, INIT: 0, INTRO: 1, PLAYING: 2}
  canvas = document.getElementById('canvas')
  c = canvas.getContext('2d')
  canvas.width = document.body.clientWidth
  canvas.height = document.body.clientHeight

  showBonus = false

  # Splashscreen
  splash = new Sprite canvas.width / 2 - 160, canvas.height / 2 - 240, "splash.png"
  splash.image.onload = () ->
    splash.draw c

  # Counter
  counter = new Sprite 3, 3, "counter.png"
  twitter = new Sprite canvas.width - 30, 3, "twitter.png"
  twitter.setSize 30, 30

  reset = new Sprite 75, 1, "reset.png"
  reset.setSize 60, 18

  # Player
  player = new Player
  player.setSize 30, 30

  # Apple
  apple = new Apple
  apple.setSize 30, 30
  apple.generate canvas

  #}}}

  #{{{ - Draw
  draw = () ->
    if State._current == State.INTRO
      c.fillStyle = '#000000'
      c.fillRect 0, 0, canvas.width, canvas.height
      splash.draw c
      setTimeout () ->
        State._current = State.PLAYING
        draw()
      , 2000
    else if State._current == State.PLAYING
      c.fillStyle = '#000000'
      c.fillRect 0, 0, canvas.width, canvas.height

      # Add counter
      phrase = "X" + FormatNumberLength(player.score, 4)
      c.font = 'bold 16px Helvetica, sans-serif'
      c.fillStyle = '#FFFFFF'
      c.fillText phrase, 20, 16
      counter.draw c
      reset.draw c
      twitter.draw c

      apple.draw c
      player.draw c

      if (showBonus)
        c.font = 'bold 32px Helvetica, sans-serif'
        c.fillStyle = '#FFFFFF'
        mt = c.measureText(phrase)
        xcoord = (canvas.width / 2) - (mt.width / 2)
        c.fillText phrase, xcoord, canvas.height / 2 - 16
        setTimeout () ->
          showBonus = false
          draw
        , 500
  #}}}

  $("#canvas").bind("touchstart", onTouchStart)
  $("#canvas").bind("mousedown", onTouchStart)
  $("#canvas").bind("touchend", onTouchEnd)
  $("#canvas").bind("mouseup", onTouchEnd)

  window.onorientationchange = () ->
    setupCanvasSize()
    apple.generate canvas

  setupCanvasSize()

  State._current = State.INTRO
  draw()

