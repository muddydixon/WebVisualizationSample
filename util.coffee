'use strict'

((global)->
  #
  # CSSの指定と同様の方法でmarginを利用できるようにする
  #
  global.Margin = class Margin
    constructor: (args...)->
      @top = 0
      @right = 0
      @bottom = 0
      @right = 0
      @width = 0
      @height = 0

      if args.length is 1
        @top = @right = @bottom = @left = args[0]
      else if args.length is 2
        @top = @bottom = args[0]
        @right = @left = args[1]
      else if args.length is 3
        @top = args[0]
        @bottom = args[2]
        @right = @left = args[1]
      else if args.length is 4
        [@top, @right, @bottom, @left] = args

      @width = @right + @left
      @height = @top + @bottom
    toString: ()->
      return [@top, @right, @bottom, @left].map((d)-> "#{d}px").join(" ")

)(window)
