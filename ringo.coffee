$ ->
  window.top.scrollTo 0, 0

  requestAnimFrame =
      window.requestAnimationFrame ||
      window.webkitRequestAnimationFrame ||
      window.mozRequestAnimationFrame ||
      window.oRequestAnimationFrame ||
      window.msRequestAnimationFrame ||
      ((callback, element) ->
        window.setTimeout(callback, 1000/60)
      )

  #{{{ - Classes
  class Blob
    constructor: () ->
      @colors = ['#999', '#f99', '#99f', '#f9f', '#990', '#909', '#099']

    generate: () ->
      @x = Math.floor(Math.random()*(canvas.width - 15))
      @y = Math.floor(Math.random()*(canvas.height- 30))
      @color = Math.floor(Math.random()*@colors.length)
      @size = 50 + Math.random() * 10
      @grow = Math.random()*-6 + 3

    draw: (c) ->
      @size += @grow
      @grow = -@grow if @size < 30 or @size > 80

      c.strokeStyle = @colors[@color]
      c.lineWidth = 1
      c.beginPath()
      c.rect(@x-@size/2, @y-@size/2, @size, @size)
      c.closePath()
      c.stroke()

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
      super 50, 50, "boy.png", 30, 30
      initScore = parseInt(localStorage.getItem("ringo-score"))
      if isNaN(initScore)
        initScore = 0
        localStorage.setItem "ringo-score", 0
      @score = initScore
      @dx = 0
      @dy = 0
      @speed = 10
      @facing = 0
      @frame = 0

    moveDelta: (dx, dy) ->
      @dx += dx
      @dy += dy

    draw: (c) ->
      if Math.abs(@dx) > 0 or Math.abs(@dy) > 0
        if Math.abs(@dx) < 2 and Math.abs(@dy) > 2
          if @dy < 0
            @facing = 3
          else
            @facing = 2
        else
          if @dx < 0
            @facing = 1
          else
            @facing = 0

      if @dx != 0
        mx = if @speed <= Math.abs(@dx) then @speed else Math.abs(@dx)
        @x += (mx * sign(@dx))
        @dx -= (mx * sign(@dx))

      if @dy != 0
        my = if @speed <= Math.abs(@dy) then @speed else Math.abs(@dy)
        @y += (my * sign(@dy))
        @dy -= (my * sign(@dy))

      @frame += 1
      @frame = 0 if @frame == 12

      @frame = 0 if @dx == 0 and @dy == 0

      @x = 0 if (@x < 0)
      @y = 0 if (@y < 0)
      @x = canvas.width - 15 if (@x > canvas.width - 15)
      @y = canvas.height - 30 if (@y > canvas.height - 30)

      c.drawImage(@image, parseInt(@frame / 4) * 32, @facing * 32, 32, 32, @x, @y, @w, @h)

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
        game.generateBlobs()

        if (player.score % 10 == 0)
          game.showBonus = true
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
      @counter = new Sprite 3, 28, "counter.png"
      @info = new Sprite canvas.width - 23, 25, "info.png"
      @player = new Player
      @apple = new Apple
      @apple.generate canvas
      @touching = false
      @touchx = 0
      @touchy = 0
      @rotation = 0

      @blobs = [new Blob, new Blob, new Blob, new Blob,
                new Blob, new Blob, new Blob, new Blob]
      this.generateBlobs()

    generateBlobs: () ->
      for blob in @blobs
        do (blob) ->
          blob.generate()

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
        , 2000
      else if this.isPlaying()
        for blob in @blobs
          do (blob) ->
            blob.draw c

        if @touching

          if @player.dx != 0 or @player.dy != 0
            @rotation += 5
            @rotation = 0 if @rotation > 360

          c.save()
          c.translate @touchx, @touchy
          c.rotate @rotation*Math.PI / 180

          c.strokeStyle = '#999'
          c.lineWidth = 1
          c.beginPath()
          c.rect(-25, -25, 50, 50)
          c.closePath()
          c.stroke()

          c.restore()

        # Add counter
        phrase = "X" + FormatNumberLength(@player.score, 4)
        c.font = 'bold 16px Helvetica, sans-serif'
        c.fillStyle = '#FFFFFF'
        c.fillText phrase, 20, 41
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
          , 500
      else if this.isSetting()
        @settings.draw c
        phrase = @player.score
        c.font = 'bold 32px Helvetica, sans-serif'
        c.fillStyle = '#FFFFFF'
        mt = c.measureText(phrase)
        c.fillText phrase, canvas.width / 2 - mt.width / 2, canvas.height / 2 + 125
      requestAnimFrame(game.draw)

  #}}}

  #{{{ - Utility Functions
  sign = (num) ->
    if num < 0 then -1 else 1

  FormatNumberLength = (num, length) ->
    r = "" + num
    while r.length < length
      r = "0" + r
    r

  setupCanvasSize = () ->
    canvas.width = document.body.clientWidth
    canvas.height = document.body.clientHeight
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
      game.touching = true
      game.touchx = localPosition.x
      game.touchy = localPosition.y
      if hitTest(localPosition, canvas.width - 30, canvas.width, 25, 55)
        game.setSetting()
        return

    else
      if hitTest(localPosition, canvas.width / 2 + 120, canvas.width / 2 + 150, canvas.height / 2 - 240, canvas.height / 2 - 215)
        game.setPlaying()
        return

      if hitTest(localPosition, canvas.width / 2 + 70, canvas.width / 2 + 140, canvas.height / 2 + 130, canvas.height / 2 + 165)
        if (confirm("Would you like to reset your score?"))
         game.player.score = 0
         localStorage.setItem "ringo-score", 0
        return

      if hitTest(localPosition, canvas.width / 2 - 125, canvas.width / 2 + 125, canvas.height / 2 + 175, canvas.height / 2 + 225)
        if (confirm("Would you like to reset your visit m7kenji.com?"))
          window.location = "http://m7kenji.com"
        return

      if hitTest(localPosition, canvas.width / 2 + 70, canvas.width / 2 + 110, canvas.height / 2 + 50, canvas.height / 2 + 90)
        if (confirm("Would you like to tweet your score?"))
          window.location = "http://twitter.com/home?status=" + escape("I have collected " + game.player.score + " apples so far. http://zaki.github.com/ringo-html5 Get the iPhone App: http://t.co/9OK31BL #ringo_html")
        return

    lastTouchPoint = { x: localPosition.x, y: localPosition.y }
    $("#canvas").bind(("touchmove"), onTouchMove)
    $("#canvas").bind(("mousemove"), onTouchMove)

  onTouchMove = (event) ->
    touch = getTouchEvent(event)
    localPosition = getCanvasLocalCoordinates(touch.pageX, touch.pageY)

    game.touchx = localPosition.x
    game.touchy = localPosition.y

    dx = localPosition.x - lastTouchPoint.x
    dy = localPosition.y - lastTouchPoint.y
    lastTouchPoint = { x: localPosition.x, y: localPosition.y }
    game.player.moveDelta dx/1.2, dy/1.2
    game.apple.hitTest game.player


  onTouchEnd = (event) ->
    game.touching = false
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
