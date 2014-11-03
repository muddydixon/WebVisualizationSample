'use strict'
############################################################
#
# サンプルデータ生成
#
((global)->
  HIGH = "high"
  MID  = "mid"
  LOW  = "low"

  GOOD = "good"
  BAD  = "bad"

  class User
    @patienceProp:
      high: d3.random.normal(0.7, 0.1)
      mid: d3.random.normal(0.6, 0.1)
      low: d3.random.normal(0.2, 0.1)
    constructor: (@id, @_patience)->
      @begin = new Date(Date.now() + (0|Math.random() * 1000 * 3600 * 24 * 7))
      @now = @begin.getTime()
      @patience = Math.max(0, Math.min(1, User.patienceProp[@_patience]()))
    play: (game)->
      log = []
      for stage, idx in game.stages
        log.push
          time: new Date(@now)
          userId: @id
          stageId: idx
        @now = @now + 15 * 1000 + (0|Math.random() * 1000 * 60 * (1 - stage.quality))
        clearRatio = d3.random.normal(@patience - (1 - stage.quality), 0.1)()
        unless clearRatio > 0
          break
      log

  class Stage
    @qualityProp:
      bad:  d3.random.normal(0.5, 0.1)
      good: d3.random.normal(0.6, 0.1)
    constructor: (@id, @_quality)->
      @quality = Math.max(0, Math.min(1, Stage.qualityProp[@_quality]()))

  class Game
    constructor: (@length, @quality)->
      @quality = Math.min 1, @quality
      badStageMax = 0|@length * (1 - @quality)
      badStageNum = 0

      @stages = [0..length - 1].map (i)=>
        q = GOOD
        if badStageNum < badStageMax and Math.random() > @quality
          badStageNum++
          q = BAD
        new Stage(i, q)

  game = new Game(20, 0.6)

  getSampleData = (num)->
    gamelog = []
    for i in [0..num - 1]
      user = new User(i, HIGH)
      log = user.play(game)
      gamelog.push.apply gamelog, log
    gamelog

  global.getSampleData = getSampleData
)(window)
