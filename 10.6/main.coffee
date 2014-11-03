'use strict'
# 描画エリアの情報
margin = new Margin(50)
[width, height] = [600, 100]

hourInterval = 3
#------------------------------------------------------------
#
# ## showVideoList
#
# 動画メタデータの視聴回数上位を表示するハンドラ
#
# * @param  d オブジェクト イベントの対象となった要素に紐づくデータ
#
showVideoList = (d)->
  # リスト要素を作成
  $list = $('<ul>')
  # 桁区切りのフォーマットを作成
  format = d3.format(',')
  # 時間のフォーマット
  tFormat = d3.time.format('%Y/%m/%d(%a) %H')
  # 動画データを視聴回数の降順にソートして上位20件
  for video in d.values.videos.sort((a, b)-> b.view_counter - a.view_counter).slice(0, 20)
    # リストの各要素を作成
    $list.append $('<li>').append(
      $('<a>', {href: "http://www.nicovideo.jp/watch/#{video.video_id}"}).text(video.title).css('font-weight': 'bold')
      $('<span>').text(" (#{format(video.view_counter)} view / #{tFormat(new Date(video.upload_time))})")
    )
  # 先のリストを削除
  $('#videos .list ul').remove()
  # 新しいリストを追加
  $('#videos .list').append $list

#------------------------------------------------------------
#
# ## showCommentList
#
# コメントメタデータを表示するハンドラ
#
# * @param  d オブジェクト イベントの対象となった要素に紐づくデータ
#
showCommentList = (d)->
  # リスト要素を作成
  $list = $('<ul>')
  # コメントデータの先頭20件
  for comment in d.values.comments.sort((a, b)-> a.no - b.no).slice(0, 20)
    # リストの各要素を作成
    $list.append $('<li>').append(
      $('<span>').text(comment.comment).css('font-weight': 'bold')
    )
  # 先のリストを削除
  $('#comments .list ul').remove()
  # 新しいリストを追加
  $('#comments .list').append $list

#------------------------------------------------------------
#
# ## createCalenderView
#
# カレンダービューを作成する関数
#
# * @param  target           文字列  カレンダービューを追加する要素のXPath
# * @param  data             配列    データ配列
# * @param  mouseoverHandler 関数    マウスオーバーイベントに対するハンドラ
#
createCalenderView = (target, data, mouseoverHandler)->
  # データの範囲を取得
  xExtent = d3.extent data, (d)-> +d.key
  yExtent = [0, 24 / hourInterval - 1]
  # 値の最大値を取得
  valueMax = d3.max data, (day)-> d3.max day.values, (hour)-> hour.values.v

  # セルのサイズを計算
  cellSize = width / (d3.range(xExtent[0], xExtent[1], 1000 * 60 * 60 * 24).length + 1)

  # x、yおよび色のスケールを作成
  x = d3.time.scale().domain(xExtent).range([0, width])
  y = d3.scale.linear().domain(yExtent).range([height, 0])
  color = d3.scale.linear().domain([0, valueMax / 2, valueMax]).range(["#0000FF", "#FFFFFF", "#FF0000"])

  # svg要素を作成
  svg = d3.select("#{target} .visualization").append("svg")
    .attr("width", width + margin.width).attr("height", height + margin.height)
    .append("g").attr("width", width).attr("height", height)
    .attr("transform", "translate(#{margin.left},#{margin.top})")

  # 日付に対応するグループ要素を作成
  day = svg.selectAll('g').data(data).enter()
    .append('g')
    .attr('transform', (d)-> "translate(#{x(+d.key)}, 0)")

  # 時間毎のセルを作成
  hour = day.selectAll('rect').data((d)-> d.values).enter()
    .append('rect').attr('width', cellSize).attr('height', cellSize)
    .attr('y', (d)-> cellSize * +d.key)
    .attr('fill', (d)-> color(d.values.v)).attr('stroke', 'grey')
    .style('cursor', 'pointer')

  # x軸、y軸の値を作成
  xaxis = d3.svg.axis().scale(x).tickFormat(d3.time.format("%m/%d"))
  xAxis = svg.append('g').call(xaxis).attr('class', 'axis')
    .attr('transform', "translate(0, #{8 * cellSize})")
  yText = svg.selectAll('text.yaxis').data([yExtent[0].. yExtent[1]]).enter()
    .append('text').classed('yaxis', true).text((d)-> "#{d * 3} - #{(d + 1) * 3}")
    .attr('dy', (d, idx)-> cellSize * (idx + 1)).attr('dx', -50)

  # ハンドラがある場合は、ハンドラに指定
  # クリックでトグル
  if mouseoverHandler
    m = mouseoverHandler
    hour.on('mouseover.showlist', m)
    .on('click', (d)->
      m = if m then null else mouseoverHandler
      hour.on('mouseover.showlist', m)
    )


#------------------------------------------------------------
#
# # ビデオデータを取得してカレンダービューのヒートマップを作成
#
$.get "video.dat", (text)->
  videos = []
  for line in text.split(/\r?\n/)
    try
      videos.push JSON.parse(line)
    catch err
      err

  videos = videos.filter (d)-> new Date(d.upload_time) < new Date(2007, 4, 0)

  dataByDayAndHour = d3.nest()
    .key((d)-> d3.time.day(new Date(d.upload_time)).getTime())
    .sortKeys((a, b)-> a - b)
    .key((d)-> 0|new Date(d.upload_time).getHours() / hourInterval) # 整数化 (0|少数)
    .sortKeys((a, b)-> a - b)
    .rollup((values)->
      v: values.length
      videos: values
    )
    .entries(videos)

  createCalenderView("#videos", dataByDayAndHour, showVideoList)

#
# # コメントデータを取得してカレンダービューのヒートマップを作成
#
$.get "comment.dat", (text)->
  comments = []
  for line in text.split(/\r?\n/)
    try
      obj = JSON.parse(line)
      comments.push obj if new Date(obj.date * 1000) < new Date(2007, 4, 0)
    catch err
      err

  dataByDayAndHour = d3.nest()
    .key((d)-> d3.time.day(new Date(d.date * 1000)).getTime())
    .sortKeys((a, b)-> a - b)
    .key((d)-> 0|new Date(d.date * 1000).getHours() / hourInterval) # 整数化 (0|少数)
    .sortKeys((a, b)-> a - b)
    .rollup((values)->
      v: values.length
      comments: values
    )
    .entries(comments)

  createCalenderView("#comments", dataByDayAndHour, showCommentList)
