'use strict'
############################################################
#
# 料箱ひげ図
#
#
do ()->
  d3.svg.bibox = ()->
    scaleX = (d)-> d
    valueX = (d)-> d.x
    scaleY = (d)-> d
    valueY = (d)-> d.y
    whiskerWidth = 30

    # 最大・最小のひげを描画
    whisker = (source, target, isX)->
      ()->
        s = this.append('g').classed('whisker', true)
        mainPath = "M#{source[0]},#{source[1]}L#{target[0]},#{target[1]}"
        whiskerPath = "M#{source[0] - whiskerWidth / 2},#{target[1]}L#{source[0] + whiskerWidth / 2},#{target[1]}"
        if isX
          whiskerPath = "M#{target[0]},#{target[1] - whiskerWidth / 2}L#{target[0]},#{target[1] + whiskerWidth / 2}"
        s.append('path').attr('d', mainPath)
        s.append('path').attr('d', whiskerPath)

    # 5つの値(中央値、最大値、最小値、第一四分位、第三四分位)を計算する
    getFive = (data)->
      max: Math.max.apply Math, data
      min: Math.min.apply Math, data
      first: d3.quantile data, 0.25
      third: d3.quantile data, 0.75
      median: d3.median data

    # スケールを適用した5つの値を計算する
    getScaledFive = (five, scale)->
      iqr = five.third - five.first
      min = scale(five.min)
      mim = scale(five.first - 1.5 * iqr) if five.min < five.first - 1.5 * iqr
      max = scale(five.max)
      max = scale(five.third + 1.5 * iqr) if five.max > five.third + 1.5 * iqr

      min: min
      max: max
      median: scale(five.median)
      first: scale(five.first)
      third: scale(five.third)

    # box本体
    box = (g)->
      g.each ()->
        g = d3.select(this)
        # データを取得
        data = this.__data__

        # x軸、y軸の値を取得
        arrX = data.map(valueX).filter((d)-> not isNaN d).sort((a, b)-> a - b)
        arrY = data.map(valueY).filter((d)-> not isNaN d).sort((a, b)-> a - b)

        # 5つの値を計算
        fiveX = getFive(arrX)
        fiveY = getFive(arrY)

        # Interquartile Rangeを計算
        iqrX = fiveX.third - fiveX.first
        iqrY = fiveY.third - fiveY.first

        # 外れ値を取得
        outlier = data.filter((d)->
          not ((fiveX.first - 1.5 * iqrX) < valueX(d) < (fiveX.third + 1.5 * iqrX) and
            (fiveY.first - 1.5 * iqrY) < valueY(d) < (fiveY.third + 1.5 * iqrY)))

        # スケールされた5つの値を計算
        scaledX = getScaledFive(fiveX, scaleX)
        scaledY = getScaledFive(fiveY, scaleY)

        # 幅と高さを計算
        width  = Math.abs scaledX.third - scaledX.first
        height = Math.abs scaledY.third - scaledY.first

        # rect要素を描画
        rect = g.append('rect').attr(
          width: width, height: height, x: scaledX.first, y: scaledY.third, fill: 'none')

        # 中央値を描画
        medianLineX = g.append('line').classed('median', true).attr(
          x1: scaledX.first, x2: scaledX.first + width
          y1: scaledY.median, y2: scaledY.median)
        medianLineY = g.append('line').classed('median', true).attr(
          x1: scaledX.median, x2: scaledX.median
          y1: scaledY.third, y2: scaledY.third + height)

        # 最大値・最小値のひげを描画
        g.call(whisker(
          [scaledX.first + width / 2, scaledY.first],
          [scaledX.first + width / 2, scaledY.min]))
        g.call(whisker(
          [scaledX.first + width / 2, scaledY.third],
          [scaledX.first + width / 2, scaledY.max]))
        g.call(whisker(
          [scaledX.first, scaledY.third + height / 2],
          [scaledX.min, scaledY.third + height / 2], true))
        g.call(whisker(
          [scaledX.third, scaledY.third + height / 2],
          [scaledX.max, scaledY.third + height / 2], true))

        # 外れ値を描画
        g.selectAll('circle').data(outlier).enter().append('circle').attr(
          cx: ((d)-> scaleX(valueX(d)))
          cy: ((d)-> scaleY(valueY(d)))
          r: 3, fill: 'none'
        )

    # メソッドをセット
    box.x = (_scale)->
      return scaleX unless _scale
      scaleX = _scale
      box
    box.y = (_scale)->
      return scaleY unless _scale
      scaleY = _scale
      box
    box.valueX = (_value)->
      return valueX unless _value
      valueX = _value
      box
    box.valueY = (_value)->
      return valueY unless _value
      valueY = _value
      box
    box.whiskerWidth = (_width)->
      return whiskerWidth unless _width
      whiskerWidth = _width
      box
    box
