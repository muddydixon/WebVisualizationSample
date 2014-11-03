'use strict'
# 描画エリアの情報
margin = new Margin(30, 50)
[width, height] = [800, 500]

#------------------------------------------------------------
#
# ## 折線グラフを描画する関数
#
# * @param  target        文字列 svgを追加する要素のXPath
# * @param  data          配列   データの配列
# * @param  info          文字列 サーバ情報の名前(cpuなど)
# * @param  opt           高さや幅、マージン、タイトルなどの情報
# * @return d3.selection  chartを描いたsvg要素
#
drawChart = (target, data, info, opt)->
  # svg要素を作成
  svg = d3.select(target).append('svg')
    .attr(width:  opt.width  + opt.margin.width, height: opt.height + opt.margin.height)
  main = svg
    .append('g')
    .attr(
      width: opt.width, height: opt.height
      transform: "translate(#{opt.margin.left},#{opt.margin.top})"
    )

  # タイトルがあればtext要素を作成
  if opt.title
    svg.append('text').classed('chart-title', true).text(opt.title)
      .attr(dx: '1em', dy: '1.25em')

  # 時間の幅、サーバ情報の範囲を取得
  xExtent = d3.extent data, (d)-> new Date(d.epoch * 1000)
  yExtent = d3.extent data, (d)-> +d[info]

  # x軸、y軸、色のスケールを作成
  x = d3.time.scale().range([0, opt.width]).domain(xExtent)
  y = d3.scale.linear().range([opt.height, 0]).domain([0, yExtent[1]])
  color = d3.scale.category10()

  # 線分のpath要素のd属性値を計算する
  line = d3.svg.line().x((d)-> x(new Date(d.epoch * 1000))).y((d)-> y(+d[info]))

  # path属性を追加して描画する
  path = main.append('path').datum(data).attr(
    class: 'line'
    d: line
    fill: 'none'
    stroke: color(0)
  )

  # 軸を作成
  xaxis = d3.svg.axis().scale(x).ticks(6).tickFormat d3.time.format('%H:%M')
  yaxis = d3.svg.axis().orient('left').scale(y).tickFormat(d3.format('s')).ticks(4)
  xAxis = main.append('g').classed('axis', true).call(xaxis)
    .attr('transform', "translate(0, #{opt.height})")
  yAxis = main.append('g').classed('axis', true).call(yaxis)

  # イベントハンドラ作成
  brushend = ()->
    # アニメーションを止めるための情報としてクラスを指定
    svg.classed('brushing', not brush.empty())
    # brushの範囲を取得。ただし、emptyの場合はリセットとみなしてデータの全範囲とする。
    extent = if brush.empty() then xExtent else brush.extent()
    # スケールの変更
    x.domain(extent)
    # 軸の変更
    xAxis.call(xaxis)
    # pathのd属性の変更。brushの範囲内のデータのみで線分群を作成
    path.attr('d', line(data.filter((d)-> extent[0] < new Date(d.epoch * 1000) < extent[1])))

    # 今回のケースでは選択した範囲が最大に拡大されるので、範囲移動などは無いため、brushの網掛を削除
    brush.clear()
    gBrush.select('.extent').attr('width', 0)

  brush = d3.svg.brush().x(x).on('brushend', brushend)

  # brushを適用するgroup要素を生成
  gBrush = main.append('g').call(brush)
  gBrush.selectAll("rect")
    .attr("height", height)
    .style('opacity', .125)
    .style('shape-rendering', 'crispEdges')

  svg.update = ()->
    # データが2つ以下の場合にはなにも行わない
    return if data.length < 2
    if not svg.classed('brushing')
      # データの範囲を更新
      xExtent = d3.extent data, (d)-> new Date(d.epoch * 1000)
      yExtent = d3.extent data, (d)-> +d[info]

      # スケールのドメイン(データの範囲)を更新
      x.domain(xExtent)
      y.domain([0, yExtent[1]])

      brush.extent(xExtent)

      # transition()を作成し、その後、変更後のデータをセット
      path.transition().attr('d', line)

      # 軸の更新
      xAxis.call(xaxis)
      yAxis.call(yaxis)

  return svg

#------------------------------------------------------------
#
# ## dstatのヘッダーからサーバ情報のリストを取得する
#
# * @param  headers 文字列 サーバの情報
# * @return [hostInfo infoCategoryMap, infoLabel]
#   * hostInfo ホスト情報, infoCategoryMap 詳細のサーバ情報とカテゴリの対応, infoLabels サーバ情報のラベル
#
parseHeader = (headers)->
  hostInfo = headers[2].split(/,/).map (d)-> d.replace(/^\"|\"$/g, "")
  categoryLabels = headers[5].split(/;/)
  infoLabels  = headers[6].split(/;/)
  infoCategoryMap = {}

  # \"をトリム
  for categoryLabel, idx in categoryLabels
    categoryLabels[idx] = categoryLabel.replace(/^\"|\"$/g, "").replace(/\s/g, '_')
  for infoLabel, idx in infoLabels
    infoLabels[idx] = infoLabel.replace(/^\"|\"$/g, "").replace(/\s/g, '_')

  # カテゴリに分類 / 詳細のラベルを取得
  currentCategory = null
  for infoLabel, idx in infoLabels
    if categoryLabels[idx] isnt ""
      currentCategory = categoryLabels[idx]
    infoCategoryMap[currentCategory] = [] unless infoCategoryMap[currentCategory]
    infoCategoryMap[currentCategory].push infoLabel

    if infoLabel is currentCategory
      continue
    infoLabels[idx] = "#{currentCategory}.#{infoLabel}"

  [hostInfo[1], infoCategoryMap, infoLabels]

#------------------------------------------------------------
#
# # dstat.log を取得して、毎秒1つずつ指定したサーバ情報のデータを追加した折線グラフを描く
#
$.get("dstat.log").done (log)->
  # セミコロン separated values の parserを作成
  semicolonSv = d3.dsv(";", "text/ssv")
  # 1行1レコードに分割
  lines = log.split(/\n/)
  # ヘッダを parse
  [host, infoCategoryMap, infoLabels] = parseHeader(lines.slice(0, 7))

  lines = lines.slice(7)
  # レコードをパースしてJSONのデータに変換
  alldata = semicolonSv.parse(infoLabels.join(';') + "\n" + lines.join('\n'))
  data = []

  # 下記の情報を表示する
  infos = ["net/total.recv", "net/total.send", "dsk/total.read", "dsk/total.writ", "io/total.read", "io/total.writ"]
  svgs = []
  for info in infos
    # グラフを描く
    svgs.push drawChart("body", data, info, {
      width: width
      height: 60
      margin: margin
      title: info
      })

  # 毎秒ひとつデータを取得して、反映
  timer = setInterval ()->
    if alldata.length is 0
      return clearInterval timer
    data.push alldata.shift()
    for svg in svgs
      svg.update()
  , 1000
