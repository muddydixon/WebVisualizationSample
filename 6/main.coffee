'use strict'
# 描画エリアの情報
margin = new Margin(100, 50)
[width, height] = [400, 400]

#------------------------------------------------------------
#
# ## drawBMI
#
# BMIの折線グラフを描く
#
# * @param  target   文字列/selection SVGを追加する要素
# * @param  dataurl  文字列           データのURL
#
drawBMI = (target, dataurl)->
  color = d3.scale.category10()
  d3.csv dataurl, (data)->
    d3.select(target).append('h2').text("BMIの折線グラフ")
    svg = d3.select(target).append('svg').attr(width: width + margin.width, height: height + margin.height)
    main = svg.append('g').attr(
      width: width, height: height
      transform: "translate(#{margin.left},#{margin.top})"
    )

    # スケール
    x = d3.scale.ordinal().rangePoints([0, width])
      .domain(data.map (d)-> d["BMI"])
    y = d3.scale.linear().range([height, 0]).domain([0, d3.max(data, (d)-> +d["全体"])])

    # パスデータ生成関数
    line = d3.svg.line().x((d)-> x(d["BMI"])).y((d)-> y(+d["全体"]))

    # 軸
    main.append('g').call(d3.svg.axis().scale(x)
      .tickValues(x.domain().filter (d, idx)-> (idx % 2) is 0))
      .attr(transform: "translate(0,#{height})")
      .selectAll('path,line').attr(stroke: 'grey', fill: 'none')
    main.append('g').call(d3.svg.axis().scale(y).orient('left'))
      .selectAll('path,line').attr(stroke: 'grey', fill: 'none')

    # ラベル
    main.append('text').text('年齢')
      .attr(transform: "translate(#{width / 2},#{height + margin.bottom / 2})")
    main.append('text').text('BMI')
      .attr(transform: "translate(#{- margin.left / 2},#{height / 2}) rotate(-90)")

    main.append('path').datum(data).attr(
      d: line
      stroke: color(0)
      fill: 'none'
    )

# ------------------------------------------------------------
#
# ## drawBMIgender
#
# 男女のBMIの折線グラフを描く
#
# * @param  target   文字列/selection SVGを追加する要素
# * @param  dataurl  文字列           データのURL
#
drawBMIgender = (target, dataurl)->
  color = d3.scale.category10()
  d3.csv dataurl, (data)->
    d3.select(target).append('h2').text("男女別のBMIの折線グラフ")
    svg = d3.select(target).append('svg').attr(width: width + margin.width, height: height + margin.height)
    main = svg.append('g').attr(
      width: width, height: height
      transform: "translate(#{margin.left},#{margin.top})"
    )

    # スケール
    x = d3.scale.ordinal().rangePoints([0, width])
      .domain(data.map (d)-> d["BMI"])
    y = d3.scale.linear().range([height, 0]).domain([0, d3.max(data, (d)-> Math.max(+d["男性"], +d["女性"]))])

    # パスデータ生成関数
    line = d3.svg.line().x((d)-> x(d["BMI"]))

    # 軸
    main.append('g').call(d3.svg.axis().scale(x)
      .tickValues(x.domain().filter (d, idx)-> (idx % 2) is 0))
      .attr(transform: "translate(0,#{height})")
      .selectAll('path,line').attr(stroke: 'grey', fill: 'none')
    main.append('g').call(d3.svg.axis().scale(y).orient('left'))
      .selectAll('path,line').attr(stroke: 'grey', fill: 'none')

    # ラベル
    main.append('text').text('年齢')
      .attr(transform: "translate(#{width / 2},#{height + margin.bottom / 2})")
    main.append('text').text('男女別BMI')
      .attr(transform: "translate(#{- margin.left / 2},#{height / 2}) rotate(-90)")

    # 凡例
    legend = main.append('g').attr(transform: "translate(#{width - 50},#{50})")

    # それぞれ描く
    for gender, idx in ["男性", "女性"]
      # ラインのアクセサを変更
      line.y((d)-> y(+d[gender]))
      main.append('path').datum(data).attr(
        d: line
        stroke: color(gender)
        fill: 'none'
      )
      # 凡例に追記
      legend.append('text').text(gender).attr(
        fill: color(gender)
        stroke: 'none'
        dy: 16 * idx
      )


#------------------------------------------------------------
#
# ## drawBoxPlot
#
# 賃金の箱ひげ図を描く
#   10.10の箱ひげ図のd3.svg.boxを利用しています
#
# * @param  target   文字列/selection SVGを追加する要素
# * @param  dataurl  文字列           データのURL
#
drawBoxPlot = (target, dataurl)->
  d3.csv dataurl, (data)->
    d3.select(target).append('h2').text("業界ごと賃金の箱ひげ図")
    # データを整形
    jobs = {}
    for d in data
      pref = d["都道府県"]; delete d["都道府県"]
      for job, salary of d
        jobs[job] = [] unless jobs[job]
        jobs[job].push {pref: pref, salary: salary}
    jobs = d3.entries(jobs)

    # SVG要素を作成
    svg = d3.select(target).append('svg').attr(width: width + margin.width, height: height + margin.height)
    main = svg.append('g').attr(
      width: width, height: height
      transform: "translate(#{margin.left},#{margin.top})"
    )

    color = d3.scale.category10()

    # スケールを作成
    x = d3.scale.ordinal().domain(jobs.map (d)-> d.key).rangeBands([0, width], 0.5)
    y = d3.scale.linear().range([height, 0])
      .domain([0, d3.max(jobs, (d)-> d3.max(d.value, (dd)-> dd.salary))])

    # 軸
    xaxis = main.append('g').call(d3.svg.axis().scale(x))
      .attr(transform: "translate(0,#{height})")
    xaxis.selectAll('path,line').attr(stroke: 'grey', fill: 'none')
    xaxis.selectAll('text').attr(transform: "rotate(-10)").style('anchor-text': 'end')
    main.append('g').call(d3.svg.axis().scale(y).orient('left'))
      .selectAll('path,line').attr(stroke: 'grey', fill: 'none')

    # ラベル
    main.append('text').text('職業')
      .attr(transform: "translate(#{width / 2},#{height + margin.bottom / 2})")
    main.append('text').text('賃金')
      .attr(transform: "translate(#{- margin.left / 2},#{height / 2}) rotate(-90)")

    # 箱ひげ図のsvg関数
    box = d3.svg.box().values((d)-> d.value).value((d)-> d.salary).scale(y).width(x.rangeBand())
      .withHist(true)
    # 箱ひげ図を作成
    main.selectAll('g.box').data(jobs).enter().append('g').attr(
      class: 'box'
      transform: (d)-> "translate(#{x(d.key)},0)"
      stroke: (d)-> color(d.key)
    ).call(box)


#------------------------------------------------------------
#
# ## drawScatterMatrix
#
# 散布図行列を描く
#
# * @param  target   文字列/selection SVGを追加する要素
# * @param  dataurl  文字列           データのURL
# * @param  opt      オブジェクト      散布行列のサイズ、マージンの設定
#
drawScatterMatrix = (target, dataurl, opt)->
  format = (d)->
    prev = d["都道府県"]
    delete d["都道府県"]
    for k, v of d
      d[k] = +v
    {
      prev: prev
      data: d
    }
  d3.csv dataurl, format, (data)->
    d3.select(target).append('h2').text("散布図行列")

    # ラベルを取得する
    labels = Object.keys(data[0].data)

    # 個々の散布図の位置を計算
    W = d3.scale.ordinal().rangeBands([0, opt.width], .1).domain(labels)
    H = d3.scale.ordinal().rangeBands([opt.height, 0], .1).domain(labels)
    # 個々の散布図のサイズを計算
    w = W.rangeBand()
    h = W.rangeBand()

    # 範囲を取得する
    scales = {}
    for label in labels
      scales[label] =
        x: d3.scale.linear().range([0, w]).domain(d3.extent(data, (d)-> d.data[label]))
        y: d3.scale.linear().range([h, 0]).domain(d3.extent(data, (d)-> d.data[label]))
    color = d3.scale.category20()

    # svg要素を作成
    svg = d3.select('body').append('svg').attr(
      width: opt.width + opt.margin.width, height: opt.height + opt.margin.height)
    main = svg.append('g').attr(
      width: opt.width, height: opt.height, transform: "translate(#{opt.margin.left},#{opt.margin.top})")

    # 散布図を作成
    for xLabel, xid in labels
      for yLabel, yid in labels
        cell = main.append('g').attr(
          width: w, height: h, transform: "translate(#{W(xLabel)},#{H(yLabel)})")
        cell.append('rect').attr(
          width: w, height: h, fill: 'none', stroke: 'grey')

        if xid isnt yid
          cell.selectAll('circle').data(data).enter().append('circle').attr(
            cx: (d)-> scales[xLabel].x(d.data[xLabel])
            cy: (d)-> scales[yLabel].y(d.data[yLabel])
            r: 2
            fill: (d)-> color(d.prev)
          )
        else
          # 対角要素
          for k, idx in ['mean', 'median']
            cell.append('text').text(k + ": " + d3[k](data, (d)-> d.data[xLabel]).toFixed(0)).attr(
              dy: (idx + 1) * 12
              dx: w
            ).style('text-anchor': 'end', 'font-size': 10)

        # 散布図の装飾(ラベル)
        # 左端
        if xid is 0
          cell.append('g').call(d3.svg.axis().orient('left').scale(scales[yLabel].y).ticks(4))
            .selectAll('path,line').attr(fill: 'none', stroke: 'grey')
          cell.append('text').text(yLabel).attr(transform: "translate(-60,#{h / 2}) rotate(-90)")
            .style('text-anchor': 'middle')
        # 上端
        if yid is labels.length - 1
          xaxis = cell.append('g').call(d3.svg.axis().orient('top').scale(scales[xLabel].x).ticks(4))
          xaxis.selectAll('path,line').attr(fill: 'none', stroke: 'grey')
          xaxis.selectAll('text')
            .attr(transform: "rotate(90)", dx: -10, dy: 16).style('text-anchor': 'end')
          cell.append('text').text(xLabel).attr(transform: "translate(#{w / 2},-60)")
            .style('text-anchor': 'middle')

#------------------------------------------------------------
#
# # 可視化作成
#
drawBMI('body', "./bmi.csv")
drawBMIgender('body', "./bmi.csv")
drawBoxPlot('body', "./tingin.csv")
drawScatterMatrix('body', "cancer.csv", {width: 800, height: 800, margin: new Margin(100,0,0,100)})
