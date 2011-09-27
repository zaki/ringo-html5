$ ->
  window.top.scrollTo 0, 0

  #{{{ - Classes
  class Sprite
    constructor: (@x, @y, src, @w, @h) ->
      @image = new Image
      @image.src = "assets/images/" + src

    draw: (c) ->
      if @w?
        c.drawImage @image, @x, @y, @w, @h
      else
        c.drawImage @image, @x, @y

  class Player extends Sprite
    constructor: () ->
      super 50, 50, "player.png", 30, 30
      initScore = parseInt(localStorage.getItem("ringo-score"))
      if isNaN(initScore)
        initScore = 0
        localStorage.setItem "ringo-score", 0
      @score = initScore

    moveDelta: (dx, dy) ->
      @x += dx
      @y += dy
      @x = 0 if (@x < 0)
      @y = 0 if (@y < 0)
      @x = canvas.width - 15 if (@x > canvas.width - 15)
      @y = canvas.height - 30 if (@y > canvas.height - 30)

  class Apple extends Sprite
    constructor: () ->
      super 0, 0, "apple.png", 30, 30
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
          game.showBonus = true
          game.draw()
        if @isBonus
          @bonus.play()
        else
          @audio.play()
        localStorage.setItem("ringo-score", player.score)
        this.generate canvas

  class Game
    constructor: () ->
      @state = 0
      @splash = new Sprite canvas.width / 2 - 160, canvas.height / 2 - 240, "splash.png"
      @splash.image.onload = () =>
        @splash.draw c
      @showBonus = false
      @settings = new Sprite canvas.width / 2 - 160, canvas.height / 2 - 240, "settings.png"
      @counter = new Sprite 3, 3, "counter.png"
      @info = new Sprite canvas.width - 23, 2, "info.png"
      @player = new Player
      @apple = new Apple
      @apple.generate canvas

    # state-handling
    isInit: ()    -> @state == 0
    isIntro: ()   -> @state == 1
    isPlaying: () -> @state == 2
    isSetting: () -> @state == 3

    setInit: ()    -> @state = 0
    setIntro: ()   -> @state = 1
    setPlaying: () -> @state = 2
    setSetting: () -> @state = 3

    draw: () =>
      c.fillStyle = '#000000'
      c.fillRect 0, 0, canvas.width, canvas.height
      if this.isIntro()
        @splash.draw c
        setTimeout () =>
          this.setPlaying()
          this.draw()
        , 2000
      else if this.isPlaying()
        # Add counter
        phrase = "X" + FormatNumberLength(@player.score, 4)
        c.font = 'bold 16px Helvetica, sans-serif'
        c.fillStyle = '#FFFFFF'
        c.fillText phrase, 20, 16
        @counter.draw c
        @info.draw c

        @apple.draw c
        @player.draw c

        if (@showBonus)
          c.font = 'bold 32px Helvetica, sans-serif'
          c.fillStyle = '#FFFFFF'
          mt = c.measureText(phrase)
          xcoord = (canvas.width / 2) - (mt.width / 2)
          c.fillText phrase, xcoord, canvas.height / 2 - 16
          setTimeout () =>
            @showBonus = false
            this.draw()
          , 500
      else if this.isSetting()
        @settings.draw c
        phrase = @player.score
        c.font = 'bold 32px Helvetica, sans-serif'
        c.fillStyle = '#FFFFFF'
        mt = c.measureText(phrase)
        c.fillText phrase, canvas.width / 2 - mt.width / 2, canvas.height / 2 + 125

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
    game.draw() unless game.isInit()
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

    if game.isPlaying()
      if hitTest(localPosition, canvas.width - 30, canvas.width, 0, 30)
        game.setSetting()
        game.draw()
        return

    else
      if hitTest(localPosition, canvas.width / 2 + 120, canvas.width / 2 + 150, canvas.height / 2 - 240, canvas.height / 2 - 215)
        game.setPlaying()
        game.draw()
        return

      if hitTest(localPosition, canvas.width / 2 + 70, canvas.width / 2 + 140, canvas.height / 2 + 130, canvas.height / 2 + 165)
        if (confirm("Would you like to reset your score?"))
         game.player.score = 0
         localStorage.setItem "ringo-score", 0
         game.draw()
        return

      if hitTest(localPosition, canvas.width / 2 - 125, canvas.width / 2 + 125, canvas.height / 2 + 175, canvas.height / 2 + 225)
        if (confirm("Would you like to reset your visit m7kenji.com?"))
          window.location = "http://m7kenji.com"
        return

      if hitTest(localPosition, canvas.width / 2 + 70, canvas.width / 2 + 110, canvas.height / 2 + 50, canvas.height / 2 + 90)
        if (confirm("Would you like to tweet your score?"))
          window.location = "http://twitter.com/home?status=" + escape("I have collected " + game.player.score + " apples so far. http://zaki.asia/ringo Get the iPhone App: http://t.co/9OK31BL #ringo_html")
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
    game.player.moveDelta dx/1.2, dy/1.2
    game.apple.hitTest game.player

    setTimeout(game.draw, 1)

  onTouchEnd = (event) ->
    $("#canvas").unbind("touchmove", onTouchMove)
    $("#canvas").unbind("mousemove", onTouchMove)
  #}}}

  #{{{ - Game Variables
  canvas = document.getElementById('canvas')
  c = canvas.getContext('2d')
  canvas.width = document.body.clientWidth
  canvas.height = document.body.clientHeight

  game = new Game
  #}}}

  $("#canvas").bind("touchstart", onTouchStart)
  $("#canvas").bind("mousedown", onTouchStart)
  $("#canvas").bind("touchend", onTouchEnd)
  $("#canvas").bind("mouseup", onTouchEnd)

  window.onorientationchange = () ->
    setupCanvasSize()
    game.apple.generate canvas

  setupCanvasSize()

  game.setIntro()
  game.draw()

