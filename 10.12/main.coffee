'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [700, 300]

# 目的変数：ゴルフをするか、説明変数：天気、湿度、風
sampledata =
  name: 'ゴルフをするか'
  question: '天気'
  children: [
    {name: '晴れ', question: '湿度', children: [
      {name: '70%以下', member: {yes: 2, no: 0}}
      {name: '70%以上', member: {yes: 0, no: 3}}
      ]}
    {name: '曇', member: {yes: 4, no: 0}}
    {name: '雨', question: '強風', children: [
      {name: '強い', member: {yes: 0, no: 2}}
      {name: '弱い', member: {yes: 3, no: 0}}
      ]}
    ]

# 目的変数：ユーザの分類、説明変数：応援(cheer)、イベント(event)
gamedata =
  name: 'ユーザ'
  question: 'cheer'
  children: [
    {name: '<= 218.800', member: {beginner: 50}}
    {name: ' > 218.800', question: 'cheer', children: [
      {name: '> 601.412', member: {'heavy-user': 30, 'light-user': 1}}
      {name: '<= 601.412', question: 'event', children: [
        {name: '> 27.998', member: {'heavy-user': 10}}
        {name: '<= 27.998', member: {'light-user': 49, 'heavy-user': 10}}
      ]}
    ]}
  ]


#------------------------------------------------------------
#
# ## rollupResult
#
# 子要素の数を集計する関数
#
# * @param  tree          オブジェクト    木
# * @param  func          関数           集計を行う関数定義
#
rollupResult = (tree, func = d3.sum)->
  return tree.member if tree.member

  member = {}
  for child in tree.children
    e = rollupResult(child)
    for key, val of e
      member[key] = 0 unless member[key]
      member[key] += val
  (tree.member = member)

#------------------------------------------------------------
#
# ## getDominantResult
#
# 主力クラスを取得する
#  1位のみか、1位と2位の差が閾値以上の場合はそのクラス名と値を返す
#  それ以外の場合はundefinedを返す
#
# * @param  tree          オブジェクト    木
# * @param  threshold     閾値           この値以下だとクラスを返さない
# * @return object        オブジェクト
#
getDominantResult = (tree, threshold = 1)->
  sorted = d3.entries(tree.member or []).sort (a, b)-> b.value - a.value
  sum = d3.sum sorted, (d)-> d.value
  if sorted.length is 0
    return undefined
  else if (sorted.length > 1) and (sorted[0].value - sorted[1].value) < threshold
    return undefined
  else
    key: sorted[0].key
    value: sorted[0].value / sum

#------------------------------------------------------------
#
# ## drawTree
#
# 決定木を作成する関数
#
# * @param  target        文字列 svgを追加する要素のXPath
# * @param  data          配列   データの配列
#
drawTree = (target, data)->
  # svg要素を作成
  svg = d3.select(target).append('svg')
    .attr(
      width: width + margin.width
      height: height + margin.height)
  main = svg.append('g').attr(
    width: width
    height: height
    transform: "translate(#{margin.left}, #{margin.top})")

  # ノードのサイズ
  nodeSize =
    width: 110
    height: 60

  # tree レイアウトを作成
  tree = d3.layout.tree().size([width, height]).separation(()-> 1)
  # リンクを生成する関数を作成
  diagonal = d3.svg.diagonal()

  # layoutを適用して nodes と links を計算
  nodes = tree.nodes(data)
  links = tree.links(nodes)
  # 色のスケールを取得
  color = d3.scale.category10()

  # link を描画
  link = main.selectAll('g.link').data(links).enter().append('g').classed('link', true)
  link.append('path')
    .attr(
      d: diagonal
      fill: 'none'
      stroke: 'grey'
      'stroke-width': (d)-> # linkの太さ(sourceの総和に対するtargetの総和の割合)を計算
        s = d.source
        t = d.target
        d3.sum(d3.entries(t), (d)-> d.value) / d3.sum(d3.entries(s), (d)-> d.value) * 10
      )

  # node を描画
  node = main.selectAll('g.node').data(nodes).enter().append('g').attr(
    class: 'node'
    transform: (d)-> "translate(#{d.x - nodeSize.width / 2},#{d.y - nodeSize.height / 2})"
  )
  node.append('rect')
    .attr(
      width: nodeSize.width
      height: nodeSize.height
      fill: (d)->
        # 主力クラス(最も多数派のクラス)に応じて色を指定
        if dominant = getDominantResult(d)
          color(dominant.key)
        else
          'white'
      stroke: 'grey'
      rx: (d)-> if d.children? then 5 else 0
    ).style('opacity', (d)->
      # 信頼度(ある分岐によってどの程度、ひとつのクラスに絞り込めたか)に応じて透明度を指定
      if dominant = getDominantResult(d)
        dominant.value
      else
        1
    )
  node.append('text').text((d)-> d.question if d.question)
    .attr(
      dx: (d)-> nodeSize.width / 2
      dy: (d)-> nodeSize.height * 1.3
    ).style('text-anchor', 'middle')
  node.append('text').text((d)-> d.name)

  # 分岐の内訳をテキストで表示
  node.selectAll('text.breakdown').data((d)-> d3.entries(d.member)).enter()
    .append('text').classed('breakdown', true).text((e)-> "#{e.key}: #{e.value}")
    .attr(
      dx: 5
      dy: (d, idx)-> 14 * idx + 14
    )

  # 分岐の内訳を積み上げグラフで表示
  breakdownBarHeight = 12
  breakdown = node.append('g').attr(
    class: 'breakdown'
    transform: "translate(0, #{nodeSize.height - breakdownBarHeight})"
  )
  breakdown.selectAll('rect').data((d)->
    members = d3.entries(d.member)
    sum = d3.sum members, (d)-> d.value
    offset = 0
    members.forEach (d)->
      d.ratio = d.value / sum
      offset = (d.offset = offset) + d.ratio
    members
  ).enter().append('rect').attr(
    x: (d)-> d.offset * nodeSize.width
    width: (d)-> d.ratio * nodeSize.width
    height: breakdownBarHeight
    fill: (d)-> color(d.key)
    stroke: 'grey'
  )

#------------------------------------------------------------
#
# サンプルデータとゲームのサンプルデータから決定木を作成
#
rollupResult sampledata
drawTree('body', sampledata)
rollupResult gamedata
drawTree('body', gamedata)
