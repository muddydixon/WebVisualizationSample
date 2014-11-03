'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [1500, 600]

color = d3.scale.category20()
bounce = "離脱"
nodeId = 0

#------------------------------------------------------------
#
# ## drawFlow
#
# フローを描画する
#
# * @param  target   selection        可視化を描画するselection
# * @param  tree     入れ子オブジェクト  データ配列
#
drawFlow = (target, tree)->
  # 入れ子構造からノード配列とリンク配列を取得するために利用
  cluster = d3.layout.cluster().children((d)-> d?.values or [])
    .value((d)-> d.values.cnt)
  nodes = cluster.nodes(tree)
  # ノードにはユニークなIDを付けておく(削除・更新のため)
  for node, idx in nodes
    node.idx = node.idx or nodeId++
  links = cluster.links(nodes)
  # リンクの値は、ターゲットノードの値
  links.forEach (link)->
    link.value = link.target.value

  # sankey レイアウトを生成
  sankey = d3.sankey().size([width, height])
    .nodeWidth(120)
    .nodePadding(0)
    .nodes(nodes)
    .links(links)
    .layout(32)

  # パス描画のパスデータ生成用関数
  path = sankey.link()

  # リンクの描画
  # 1. 既存リンクの更新
  linkSelection = target.selectAll('.link').data(links, (d)-> "#{d.source.idx}-#{d.target.idx}")
  linkSelection.transition().attr(
    opacity: (d)-> if d.target.key is bounce then 0 else .5
  )
  linkSelection.select('path').transition().attr(
    'stroke-width': (d)-> d.dy
    d: (d)->if d.key is bounce then "" else path(d)
  )
  # 2. 削除リンク(親)の除去
  linkExit = linkSelection.exit().transition().attr(opacity: 1e-16)
  # 3. 新規リンクの追加
  linkEnter = linkSelection.enter().append('g').attr(class: 'link')
  linkEnter.append('path').attr(
    stroke: 'grey'
    fill: 'none'
    'stroke-width': (d)-> d.dy
    d: (d)-> if d.key is bounce then "" else path(d)
    opacity: (d)-> .5
  )

  # ノードの描画
  nodeSelection = target.selectAll('.node').data(nodes, (d)-> d.idx)
  # * 既存ノードの更新
  nodeSelection.transition().attr(
    transform: (d)-> "translate(#{d.x},#{d.y})"
    opacity: (d)-> if d.key is bounce then 0 else .5
  )
  nodeSelection.select('rect').transition().attr(
    width: (d)->d.dx
    height: (d)-> Math.max 1, d.dy
    fill: (d)-> color(d.key)
  )
  nodeSelection.select('text').transition().style(
    opacity: (d)-> if d.dy < 12 or d.key is bounce then 0 else 1
  )
  # * 削除ノード(親)の除去
  nodeExit = nodeSelection.exit().transition().attr(
    opacity: 1e-16
  )
  # * 新規ノードの追加
  nodeEnter = nodeSelection.enter().append('g').attr(
    class: 'node'
    transform: (d)-> "translate(#{d.x},#{d.y})"
    cursor: 'pointer'
    opacity: (d)-> if d.key is bounce then 0 else .5
  )
  nodeEnter.append('rect').attr(
    width: (d)->d.dx
    height: (d)-> Math.max 1, d.dy
    fill: (d)-> color(d.key)
  )
  nodeEnter.append('text').text((d)-> "#{d.key} (#{d.value})").attr(dy: 12).style(
    opacity: (d)-> if d.dy < 12 or d.key is bounce then 0 else 1
  )

  # ノードクリック時に深堀りを行う
  nodeEnter.on('click', (d)->
    depth = Math.min d.depth, 5
    if d.parent
      # openLeaves(d, depth)
      drawFlow(target, d.parent)
  )

#------------------------------------------------------------
#
# ## openLeaves
#
# 葉を展開する
#
# * @param  tree    オブジェクト(入れ子構造)
# * @param  depth   深さ
#
openLeaves = (tree, depth)->
  if tree.children and tree.children instanceof Array
    for child in tree.children
      openLeaves child, depth
  else
    nest = d3.nest()
    [0...depth].forEach (i)->
      nest.key((d)-> d.values[i]?.path or bounce)
    data = nest.rollup((values)->
      cnt: values.length
      children: values
    ).entries(tree.values.children)

    tree._values = tree.values
    tree.values = data


#------------------------------------------------------------
#
# フローを描く
#
# * @param  target   文字列  SVGを追加する要素
# * @param  sessions 配列    セッション配列
#
drawFlowChart = (target, sessions)->
  initDepth = 5

  svg = d3.select('body').append('svg').attr(
    width: width + margin.width
    height: height + margin.height
  )
  main = svg.append('g').attr(
    width: width
    height: height
    transform: "translate(#{margin.left},#{margin.top})"
  )

  # セッションからアクセスしたパスに基づいて入れ子構造を生成(深さ指定)
  nest = d3.nest()
  [0...initDepth].forEach (i)->
    nest = nest.key((d)-> d[i]?.path or bounce)
  data = nest.rollup((values)->
    cnt: values.length
    children: values
  ).entries sessions

  # フローを描画
  drawFlow main, data[0]

#------------------------------------------------------------
#
# ## セッション
#
class Session
  constructor: (@sid, @bounceRate = .2)->
    @accesses = []
    @begin = new Date()

  start: (path)->
    @accesses.push
      referer: ""
      path: path
      time: @begin

    @next(path)

  next: (referer)->
    lastAccess = @accesses[@accesses.length - 1]

    category = if Math.random() < .7 then "/cate#{parseInt(Math.random() * 3)}" else ""
    path = "#{category}/item#{0|Math.random() * 6}"

    @accesses.push
      referer: referer
      path: path
      time: lastAccess.time + parseInt(Math.random() * 1000 * 60 * 5)

    # 離脱率に応じてセッション終了
    if Math.random() < @bounceRate
      return @accesses.map (hist)=>
        sid:     @sid
        time:    hist.time
        path:    hist.path
        referer: hist.referer

    @next(path)

#------------------------------------------------------------
#
# # デモデータ作成
#
data = []
d3.range(0, 1000).map (i)->
  session = new Session(i)

  data.push session.start("/")

# アクセスフローの描画
drawFlowChart('body', data)
