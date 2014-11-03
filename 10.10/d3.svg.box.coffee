'use strict'
############################################################
#
# 箱ひげ図
#
do ()->
  d3.svg.box = ()->
    scale = (d)-> d
    value = (d)-> d
    values = (d)-> d
    width = 30
    whiskerWidth = 30
    withHist = false

    # 最大・最小のひげを描画
    whisker = (source, target)->
      ()->
        s = this.append('g').classed('whisker', true)
        s.append('path').attr(
          d: "M#{source[0]},#{source[1]}L#{target[0]},#{target[1]}"
        )
        s.append('path').attr(
          d: "M0,#{target[1]}L#{target[0] * 2},#{target[1]}"
        )

    # ヒストグラムを追加する関数
    hist = (data, height)->
      ()->
        histogram = d3.layout.histogram().bins(20)
        histData = histogram(data)

        y = d3.scale.linear().domain(d3.extent(histData, (d)-> d.y)).range([0, width / 2])
        height = scale(0) - scale(histData[0].dx)

        this.selectAll('rect').data(histogram(data)).enter().append('rect')
          .attr('x', 0).attr('y', (d)-> scale(d.x) - height)
          .attr('width', (d)-> y(d.y)).attr('height', height)
          .style('opacity', 0.5).attr('stroke', 'none').attr('fill', 'grey')

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
      # 基本的な配色
      # データを取得
      g.each ()->
        g = d3.select(this)

        data = values(this.__data__)

        # x軸、y軸の値を取得
        arr = data.map(value).filter((d)-> not isNaN d).sort((a, b)-> a - b)

        # 5つの値を計算
        five = getFive(arr)

        # Interquartile Rangeを計算
        iqr = five.third - five.first

        # 外れ値を取得
        outlier = data.filter((d)->
          not ((five.first - 1.5 * iqr) < value(d) < (five.third + 1.5 * iqr)))

        # スケールされた5つの値を計算
        scaled = getScaledFive(five, scale)

        # 高さを計算
        height = Math.abs scaled.third - scaled.first

        # rect要素を描画
        rect = g.append('rect').attr
          width: width, height: height, y: scaled.third, fill: 'none'

        # 中央値を描画
        medianLine = g.append('line').classed('median', true).attr(
          x1: 0, x2: width
          y1: scaled.median
          y2: scaled.median)

        # 最大値・最小値のひげを描画
        g.call(whisker([width / 2, scaled.first],[width / 2, scaled.min]))
        g.call(whisker([width / 2, scaled.third],[width / 2, scaled.max]))

        # 外れ値を描画
        g.selectAll('circle').data(outlier).enter().append('circle').attr(
          cx: width / 2, cy: ((d)-> scale(value(d))), r: 3, fill: 'none'
        )

        # ヒストグラムを描画
        if withHist
          g.append('g').call(hist(arr, height)).attr('transform', "translate(#{width / 2},0)")

    # メソッドをセット
    box.scale = (_scale)->
      return scale unless _scale
      scale = _scale
      box
    box.value = (_value)->
      return value unless _value
      value = _value
      box
    box.values = (_values)->
      return values unless _values
      values = _values
      box
    box.width = (_width)->
      return width unless _width
      width = _width
      box
    box.whiskerWidth = (_width)->
      return whiskerWidth unless _width
      whiskerWidth = _width
      box
    box.withHist = (_bool)->
      return withHist unless _bool
      withHist = _bool
      box
    box
