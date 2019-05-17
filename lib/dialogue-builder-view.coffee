{Range} = require 'atom'
{ScrollView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
Viz = require 'viz.js'  #DialogueBuilderプラグイン,グラフ出力用
fs = require 'fs'       #ファイル操作ライブラリ
d3 = require 'd3'       #svg画像ライブラリ
net = require 'net'     #通信用ライブラリ

global.jQuery = require 'jquery'
require 'bootstrap'

Message = ""
isSendMessage = false
EDITOR = null


myprof_recogWord = {}
myprof_Detail = {}


module.exports =
class DialogueBuilderView extends ScrollView
   @content: ->
      @div class: 'dialogue-builder', =>
         @div class: 'container-fluid',=>
            @div class: 'row' ,=>
               @div class: 'col-xs-12 col-sm-6', =>
                  @div class: 'panel', =>
                     @div class: 'panel-heading text-center' , =>
                        @text "デバッガ"
                     @div class: 'panel-body myBox', =>
                        @form =>
                           @input type: 'text', class:'form-group native-key-bindings',placeholder:"Message to Send MMDAgent",id: 'SendMessage'
                           @input type: 'submit' ,class: 'btn btn-default', name: 'action', value: 'SEND_MESSAGE',click: 'SEND_MESSAGE'
                        @div =>
                           @input type: 'submit' , class:'btn btn-default', name: 'action', value: 'DEBUG_CONTINUE',click: 'SEND_CONTINUE_MESSAGE'
                        @div class: 'checkbox' ,=>
                           @label =>
                              @input type: 'checkbox', id: 'followLine'
                              @text 'text Following'
               @div class: 'col-xs-12 col-sm-6' ,=>
                  @div class: 'panel', =>
                     @div class: 'panel-heading text-center' , =>
                        @text "状態情報"
                     @div class: 'panel-body myBox', =>
                        @div =>
                           @ul class: 'nav nav-tabs', =>
                              @li class: 'active', =>
                                 @a href: '#1', 'data-toggle':'tab', =>
                                    @text '利用状況'
                              @li =>
                                 @a href: '#2', 'data-toggle':'tab',=>
                                    @text '認識単語'
                           @div class: 'tab-content', =>
                              @div class:'tab-pane active', id:'1', =>
                                 @form class: "form-horizontal", =>
                                    @div class: "form-group" ,=>
                                       @textarea class: 'form-control native-key-bindings', id:'useage', rows:'5', col:"40",=>
                                          @text '利用率を表示'
                              @div class:'tab-pane', id:'2', =>
                                 @form class: "form-horizontal", =>
                                    @div class: "form-group" ,=>
                                       @textarea class: 'form-control native-key-bindings', id:'recog', rows:'5',col:"40",=>
                                          @text '認識単語の表示'
            @div class: 'row' ,=>
               @div class: 'col-xs-12 col-sm-12 ' ,=>
                  @div class: 'panel', =>
                     @div class: 'panel-heading text-center' , =>
                        @text "ビュアー"
                     @div class: 'panel-body', =>
                        @div class: 'btn-toolbar', =>
                           @div class: 'btn-group', =>
                              @input type: 'submit', class: 'btn btn-default', name: 'action', value: 'MAKE GRAPH',click: 'drawFST'
                              @input type: 'submit', class: 'btn btn-default', name: 'action', value: 'BIG',click: 'SVGBIG'
                              @input type: 'submit', class: 'btn btn-default', name: 'action', value: 'SMALL',click: 'SVGSMALL'
                     @div class: '', id: 'fst-image'

   initialize: ->
      super()

   #初期イベント追加などをやるコンストラクタ
   constructor: ({@editorId}) ->
      super()
      # イベントの設定
      document.body.addEventListener 'mousedown', onMouseDown
      document.body.addEventListener 'mousemove', onMouseMove
      document.body.addEventListener 'mouseup', onMouseUp
      @disposables = new CompositeDisposable

      if @editorId?
         @resolveEditor(@editorId)
      #local変数
      @svgW = 0
      @svgH = 0

      HOST = 'localhost'
      PORT = 39392
      isSendMessage = false
      Server = net.createServer(@socketExchange).listen PORT, HOST

   SVGBIG: (event, element) ->
      svgImage = d3.select('svg')
      if svgImage != null
         @svgW = parseInt(svgImage.attr('width'))* 1.2
         @svgH = parseInt(svgImage.attr("height")) * 1.2
         svgImage.attr("width",@svgW + "px")
         svgImage.attr("height",@svgH + "px")

   SVGSMALL: (event, element) ->
      svgImage = d3.select('svg')
      if svgImage != null
         @svgW = parseInt(svgImage.attr('width')) * 0.83
         @svgH = parseInt(svgImage.attr("height")) * 0.83
         svgImage.attr("width",@svgW + "px")
         svgImage.attr("height",@svgH + "px")


   COMMAND_TEST: (event,element) ->
      line = parseInt(2)
      if @marker?
         @marker.destroy()
      range = new Range([line, 0],[line, 10])
      @marker = EDITOR.markBufferRange(range,invalidate: 'touch',false)
      #EDITOR.decorateMarker(@marker, type: 'line', class: 'underline')
      EDITOR.decorateMarker(@marker, type: 'highlight', class: 'underline')
      console.log "test"

   #グラフ描写関数
   drawFST: (event, element) ->
      console.log "Preparing #{element.name} for lanch!"
      @redraw()
      console.log "load profile"

      
      editor = atom.workspace.getActivePaneItem()
      profPath = editor.editor.buffer.file.path
      profPath = profPath.substr(0, profPath.length - 3) + 'profile'
      profFile = fs.readFileSync(profPath, 'utf8')
      for term in profFile.split('--')
         stateNum = 0
         for line in term.split(/\r\n|\r|\n/)
            result = line.match(/StateNum: (\d+)/)
            if result?
               stateNum = result[1]
               myprof_recogWord[String(stateNum)] = ""
            else if line.indexOf("UseCount") != -1
               s = line.split(" ")
               myprof_Detail[String(stateNum)] = "利用率: " + s[1] + "\n離脱率: " + s[4] + "\n平均滞在時間: " + s[7]
               changeStateColor(String(stateNum), parseInt(parseFloat(s[1]) * 12))
            else
               myprof_recogWord[String(stateNum)] += line + "\n"
      

   # エディターIDからエディタを取得し、取得できたらビューを描画する
   resolveEditor: (editorId) ->
      resolve = =>
         @editor = @getEditorById(editorId)
         EDITOR = @editor

         if @editor?
            @handleEvents() # イベント関連初期化
            #@redraw()

      if atom.workspace?
         resolve() # atomが初期化済みならすぐ開く
      else
         @disposables.add atom.packages.onDidActivateInitialPackages(resolve) # atomが初期化されていないなら初期化後に開く

   destroy: ->
      @disposables.dispose() # subscribeしたイベントを全てunsubscribe

   handleEvents: ->
      if @editor?
         @disposables.add @editor.onDidSave => @redraw()

   redraw: ->
      @editor = @getEditorById(@editorId)
      text = @editor.getText() if @editor?

      SVGimage = fst2svg(text)
      console.log "execute"
      if SVGimage == null
         return

      preimage = document.getElementById('image')
      if(preimage)
         preimage.parentNode.removeChild(preimage)

      image = document.createElement("div")
      image.id = "image"
      image.style = "height:100%; width:100%; overflow:auto;"
      image.innerHTML = SVGimage

      document.getElementById('fst-image').appendChild(image)

      #サイズ継承
      if @svgW != 0 or @svgH != 0
         svgImage = d3.select('svg')
         svgImage.attr("width",@svgW + "px")
         svgImage.attr("height",@svgH + "px")

      return

   #スクロール関係の変数
   @isMouseDown = false
   @previousPoint = {}

   #マウス処理定義
   onMouseDown = (e) ->
      @isMouseDown = true
      @previousPoint = getPointByEvent(e)
      return

   loadProfile : ->

   onMouseMove = (e) ->
      e.preventDefault() #マウス処理の停止

      if @isMouseDown
         currentPoint = getPointByEvent(e)
         offsetX = @previousPoint.x - (currentPoint.x)
         offsetY = @previousPoint.y - (currentPoint.y)
         @previousPoint = currentPoint
         document.getElementById("image").scrollLeft += offsetX
         #document.getElementById("image").scrollTop += offsetY

      #クリック処理の定義，
      d3.selectAll('.node').on 'click', ->
         #changeStateColor(this.id.substr(1), 0)

         #クリックした状態番号の情報を表示する
         if myprof_recogWord[this.id.substr(1)]?
            d3.select('#recog').text(myprof_recogWord[this.id.substr(1)])
         else if myprof_recogWord[this.id.substr(1)] == ""
            d3.select('#recog').text("認識語なし")
         else
            d3.select('#useage').text("データがありません")

         if myprof_Detail[this.id.substr(1)]?
            d3.select('#useage').text(myprof_Detail[this.id.substr(1)])
         else
            d3.select('#useage').text("データがありません")

         #テキストエディタから状態をテキストを取得
         #先頭の番号とクリックしたノードのIDを比較し，状態番号に飛ぶ．
         #1対多変換となるため，先頭一致した状態番号を採用
         #idはn123 のような形式のため注意する
         text = EDITOR.getText() if EDITOR?
         strArray = text.split(/\r\n|\r|\n/)
         for i in [0...strArray.length-1] # i+1が行番号になる
            targetLine = strArray[i].replace(/(^\s+)|(\s+$)/g, '')
            if targetLine.split(" ")[0] == this.id.substr(1)
               EDITOR.setCursorScreenPosition([i,0])
               return

      d3.selectAll('.edge').on 'click', ->
         console.log this.id

   onMouseUp = (e) ->
      @isMouseDown = false
      return

   getPointByEvent = (e) ->
      {
         'x': e.x
         'y': e.y
      }


   #FST形式の記述をsvg画像に変換
   fst2svg =  (fsttext) ->

      strArray = fsttext.split(/\r\n|\r|\n/)
      ans = ''
      i = 0
      clasterNum = 0
      Start_state = 0
      End_state = 0
      for i in [0..strArray.length-1] #i+1が行番号になる

         targetLine = strArray[i].replace(/(^\s+)|(\s+$)/g, '')

         if targetLine == '' || targetLine == '\n' #空白行は無視
            continue
         else if targetLine.match(/^#/) #コメント行処理
            temp = targetLine.match(/#+ *(\d+) *- *(\d+)/g)
            if temp?
               num = targetLine.match(/\d+/)
               clasterNum += 1
               Start_state = Number(num[0])
               End_state = Number(num[1])
               ans += """
               subgraph cluster#{clasterNum} {
               color = "white";
               fillcolor = "#343434";
               label = \"#{targetLine}\";
               }
               """
         else  #それ以外の行
            t = targetLine.split(/\s+/) #空白でsplit
            if t.length == 4  #引数4つ
               #edge生成,
               ans += "#{t[0]}->#{t[1]} [id = \"#{t[2]}/#{t[3]}\"];\n"
               #ID情報埋め込み
               ans += "#{t[0]}[id = \"n#{t[0]}\"];\n"
               ans += "#{t[1]}[id = \"n#{t[1]}\"];\n"
               #subcluster設定
               if Start_state <= Number(t[0]) && Number(t[0]) <= End_state
                  ans += """
                  subgraph cluster#{clasterNum} {
                  #{t[0]};
                  }
                  """
               if Start_state <= Number(t[1]) && Number(t[1]) <= End_state
                  ans += """
                  subgraph cluster#{clasterNum} {
                  #{t[1]};
                  }
                  """
            else  #コンパイルエラー
               console.log 'error'+ ':'+ ' line:' + i + ':' + targetLine
               #textArea = document.getElementById ('console')
               #textArea.value = 'error'+ '  ' + ans + ' line:' + i
               #return null
      GraphFormat =
         'graph [
         bgcolor = "#343434",
         concentrate = true,
         constraint = true,
         fontcolor	="white",
         fontsize = 14,
         style = "filled",
         rankdir = LR
         ];'

      EdgeFormat =
         'edge [
         colorscheme = "rdylgn11",
         fontcolor = white,
         color = 7,
         fillcolor = 11,
         labelfloat = true,
         penwidth="3"
         ];'

      NodeFormat =
         'node[
         colorscheme = "rdylgn11",
         shape = "circle",
         style = "solid,filled",
         fontcolor = 6,
         fontsize = 10,
         color = 7,
         fillcolor = 11,
         ];'
      FormatText = "digraph G {\n#{GraphFormat}\n#{NodeFormat}\n#{EdgeFormat}\n#{ans}\n}"
      #fs.writeFile 'C:/Users/masaki/.atom/packages/dialogue-builder/test.txt', FormatText, 'utf-8', (err)->
      console.log FormatText
      ret = Viz(FormatText,
         engine: "dot"
         format: "svg",
         totalMemory: 1024 * 1024 * 1024)
      console.log ret
      return ret

   getTitle: ->
      "#{@editorId} DialogueBuilder"

   getEditorById: (editorId) ->
      for editor in atom.workspace.getTextEditors()
         return editor if editor.id?.toString() is editorId.toString()
      null

   @marker
   setLineHighlight = (line) ->
      line = parseInt(line)
      if @marker?
         @marker.destroy()
      EDITOR.setCursorScreenPosition([line,0])
      range = new Range([line, 0],[line + 1, 0])
      @marker = EDITOR.markBufferRange(range,invalidate: 'touch')
      EDITOR.decorateMarker(@marker, type: 'line', class: 'highlight')

   procRecivedMessage = (msg) ->
      msg = msg + ""
      #console.log msg
      if msg.match(/VIManager: Status/)
         checkbox = d3.select('#followLine').property("checked")
         if(checkbox)
            presentLine = msg.match(/VIManager: Status: \[main:(\d+)\]/)
            #console.log presentLine[1]
            setLineHighlight(presentLine[1])

         msg = msg.split(/\r\n|\r|\n/)
         for i in [0..msg.length]
            transiton = String(msg[i]).match(/"(.*?)"/)
            if transiton?
               transiton[0] = transiton[0].substring(1,transiton[0].length - 1)
               state = transiton[0].split(/ +/)
               changeState(state[0],state[1])

   changeState = (prev,next)->
      if prev != next && isFinite(prev) && isFinite(next)
         console.log "changeState:" + prev + " to " + next
         nextStateNode = d3.select("\#n#{next}").select('ellipse')
         prevStateNode = d3.select("\#n#{prev}").select('ellipse')
         if nextStateNode? && prevStateNode?
            #現在ステートの色を変更
            nextStateNode.attr 'fill', color(0)
            prevStateNode.attr 'fill', color(1)

            i = 1
            #過去のステートをカラーフェードアウトさせる
            if prevStateNode.attr('fill') != color(0)
               timer_id = setInterval(( ->
                  if prevStateNode.attr('fill') == color(0)
                     clearInterval timer_id
                     prevStateNode.attr 'fill',color(0)
                  i++
                  if i == 11
                     clearInterval timer_id
                  prevStateNode.attr 'fill', color(i)
                  return
               ), 70)

   changeStateColor = (stateNum)->
      console.log "stateNum"
      stateNode = d3.select("\#n#{stateNum}").select('ellipse')
      if stateNode?
         #現在ステートの色を変更
         stateNode.attr 'fill', color(8)

   #colorIndexは0-11で指定．0のほうが濃い
   changeStateColor = (stateNum, colorIndex)->
      console.log "stateNum"
      stateNode = d3.select("\#n#{stateNum}").select('ellipse')
      if stateNode?
            #現在ステートの色を変更
            stateNode.attr 'fill', color2(colorIndex)

   Message = ""
   #socket通信実装部
   socketExchange : (sock) ->
      ##メッセージ送信
      setInterval (->
         if isSendMessage == true
            if Message?
               sock.write Message
               Message = ""
            isSendMessage = false
      ), 50

      parent = this
      sock.on 'data', (msg) ->
         procRecivedMessage(msg)

      # 'close'イベントハンドラー
      sock.on 'close', (had_error) ->
         console.log 'CLOSED. Had Error: ' + had_error
         return
      # 'errer'イベントハンドラー
      sock.on 'error', (err) ->
         console.log 'ERROR: ' + err.stack
         return
      return

   SEND_STATE_STOP:(state)->
      if state?
         Message = "DEBUG_SET_BREAKSTATE|" + state
         isSendMessage = true

   SEND_CONTINUE_MESSAGE :->
      console.log "hit"
      Message = "DEBUG_CONTINUE"
      isSendMessage = true

   SEND_MESSAGE: (event, element) ->
      Message = document.getElementById('SendMessage').value
      isSendMessage = true
      console.log "hit"

   color = d3.scaleLinear().domain([0, 11]).range(["#f46d43", "#006837"]).interpolate(d3.interpolateLab)
   color2 = d3.scaleLinear().domain([0, 11]).range(["#0000FF", "#f46d43"]).interpolate(d3.interpolateLab)
