'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [800, 500]

#------------------------------------------------------------
#
# ## getOrientation
#
# 方向を計算する関数
#
# * @param  d      オブジェクト リンクオブジェクト    オブジェクト source,targetを持つリンクオブジェクト
# * @return object x、yの方向ベクトル、符号、角度のオブジェクト
#
getOrientation = (d)->
  dist =
    x: d.target.x - d.source.x
    y: d.target.y - d.source.y
  sign = if dist.x > 0 then 1 else -1
  angle = Math.atan(dist.y / dist.x) / Math.PI * 180 + (1 - sign) * 90 or 0

  x: dist.x
  y: dist.y
  sign: sign
  angle: angle

#------------------------------------------------------------
#
# ## drawStateTransition
#
# 状態遷移図を作成する
#
# * @param  target        文字列 svgを追加する要素のXPath
# * @param  data          配列   データマトリクス
#
drawStateTransition = (target, data)->
  # ラベルの配列
  label = data.map (d)-> d.key
  # リンクの配列
  links = []
  data.forEach (from, fromid)->
    from.values.forEach (to)->
      if to.value > 0
        links.push
          source: fromid
          target: label.indexOf(to.key)
          value:  to.value
  # force レイアウトを生成
  force = d3.layout.force()
    .size([width, height])
    .nodes(data).charge(- height)
    .links(links)
    .linkDistance((d)-> # リンクの距離を確率に応じさせる
      (1 - d.value / 100) * height / 2)

  # 色を取得
  color = d3.scale.category10()
  # svgを追加する
  svg = d3.select(target).append('svg').attr(
    width: width + margin.width
    height: height + margin.height
  )
  # gを追加する
  main = svg.append('g').attr(
    width: width
    height: height
    transform: "translate(#{margin.left},#{margin.top})"
  )
  # 定義(ID=end-arrow)
  defs = svg.append('svg:defs')
  defs.append('marker').attr(
    id: 'end-arrow'
    viewBox: '0 0 10 10'
    refX: 6, refY: 4
    markerWidth: 6, markerHeight: 6
    orient: 'auto')
  .append('path').attr(
    d: 'M0,0L10,5L0,10z' # 三角形
    fill: 'grey'
    class: 'end-arrow')

  # リンクのデータパス
  diagonal = d3.svg.diagonal()
  # 確率とあわせて表示する矢印のパスデータ
  selfLink = ()-> # 自分から自分への遷移
    d3.svg.arc().innerRadius(20).outerRadius(25)(startAngle:Math.PI + 0.1, endAngle: 3 * Math.PI - 0.1)
  arrow = ()-> "M0,5L20,5L20,15L30,0L20,-15L20,-5L0,-5L0,5"

  # リンクを描画
  link = main.selectAll('g.link').data(links).enter().append('g').attr(
    class: 'link'
    opacity: .6
  )
  link.append('path').attr(
    class: 'line'
    fill: 'none'
    stroke: 'grey'
    'stroke-width': (d)-> # 確率に応じたリンクの太さ
      Math.sqrt d.value
  ).style('marker-end', 'url(#end-arrow)')
  link.append('text').text((d)-> "#{d.value}%")
  link.append('path').attr(
    class: 'arrow'
    d: arrow
    opacity: .3
  )

  # ノードを描画
  node = main.selectAll('g.node').data(data).enter().append('g').attr(
    attr: 'node'
    transform: (d)-> "translate(#{d.x},#{d.y})"
  )
  node.append('ellipse').attr(
    rx: 40, ry: 20
    fill: (d)-> color(d.key)
    opacity: .6
    cursor: 'pointer'
  )
  node.append('text').text((d)-> d.key).style('text-anchor', 'middle')
  node.call(force.drag) # ノードをドラッグ可能にする

  # tickイベントで毎回のノードとリンクを修正する
  force.on 'tick', (d)->
    # ノードの位置を更新
    node.attr(
      transform: (dd)-> "translate(#{dd.x},#{dd.y})"
    )
    # リンクのline位置を更新
    link.selectAll('path.line').attr(
      d: (dd)-> diagonal dd
    )
    # リンクの確率遷移の矢印の位置を更新
    link.selectAll('path.arrow').attr(
      d: (dd)-> if dd.source.x is dd.target.x then selfLink(dd.source) else arrow()
      transform: (d)->
        orient = getOrientation(d)
        x = (d.source.x + d.target.x) / 2
        y = (d.source.y + d.target.y) / 2
        "translate(#{x},#{y + orient.sign * 20}) rotate(#{orient.angle})"
    )
    # リンクの遷移確率のtext位置を更新
    link.selectAll('text').attr(
      dx: (d)->
        orient = getOrientation(d)
        (d.source.x + d.target.x) / 2
      dy: (d)->
        orient = getOrientation(d)
        (d.source.y + d.target.y) / 2 + orient.sign * 10
    ).style(
      'text-anchor': (d)-> if d.target.y - d.source.y > 0 then 'start' else 'end'
    )

  # forceの計算を開始
  force.start()

#------------------------------------------------------------
#
# データを読み込んで描画する
#
d3.csv "./transition_matrix.csv",
  # レコードパース関数
  (d)->
    key: d["From\\To"]
    values: ({key: k, value: +d[k]} for k in Object.keys(d).filter((d)-> d isnt 'From\\To'))
  (data)->
    drawStateTransition('body', data)
