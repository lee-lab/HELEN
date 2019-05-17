url = require 'url'
fs = require 'fs'
{Range} = require 'atom'
DialogueBuilderView = require './dialogue-builder-view'
{CompositeDisposable} = require 'atom'

module.exports = DialogueBuilder =

  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'dialogue-builder:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'dialogue-builder:elasticTab': => @elasticTab()
    @subscriptions.add atom.commands.add 'atom-workspace', 'dialogue-builder:checkdict': => @checkdict()

    #カスタムオープナーを定義
    atom.workspace.addOpener (uriToOpen) ->
      console.log uriToOpen
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return
      return unless protocol is 'dialogue-builder:' # プロトコルがこのプラグインのプロトコルならビューを生成する

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      new DialogueBuilderView editorId: pathname.substring(1)

  deactivate: ->
    @subscriptions.dispose()

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    #プレビュー窓を作成
    options =
    split: 'right' # 画面を分割して右側に表示する
    searchAllPanes: true

    uri = @uriForEditor(editor)

    atom.workspace.open(uri,options)

  elasticTab: ->
    editor = atom.workspace.getActiveTextEditor()
    Text = editor.getText()

    Text = Text.split(/\r\n|\r|\n/)
    tab = " "
    Indent = [0,0,0]

    for i in [0..Text.length-1]
      SpText = Text[i].split(/\s+/)
      SpText[0] = SpText[0].replace(/(^\s+)|(\s+$)/g, '')
      console.log SpText
      if SpText[0] != "" and SpText[0].charAt(0) != "#"
          for j in [0..2]
            if SpText[j]? && SpText[j].length + @numOfnonChar(SpText[j]) > Indent[j]
              Indent[j] = SpText[j].length + @numOfnonChar(SpText[j])

    OText = []
    for i in [0..Text.length-1]
      SpText = Text[i].split(/\s+/)
      SpText[0] = SpText[0].replace(/(^\s+)|(\s+$)/g, '')
      if SpText != "" and SpText[0].charAt(0) != "#" and SpText.length >= 4
          for j in [0..2]
              OText += SpText[j]

              OText += tab.repeat(3 + Indent[j] - SpText[j].length)
          OText += SpText[j] + "\n"
      else
          OText += Text[i] + "\n"
    #console.log OText
    editor.setText(OText)

#テスト
  checkdict: ->
    console.log __dirname#これが本体の名前
    #userDic = fs.readFileSync(__dirname + '/dict/user.dic.lnk', 'utf8')
    console.log "do checkdict"
    #辞書ファイル読込
    #fs.readFile 'C:/Users/user/.atom/packages/DialogueBuilder/dict/web.60k.htkdic', 'utf8', (err, text) ->
    fs.readFile __dirname + '/dict/web.60k.htkdic', 'utf8', (err, text) ->
      editor = atom.workspace.getActiveTextEditor()

      userDicpath = editor.getPath()
      userDicpath = userDicpath.substr(0, userDicpath.length - 3) + 'dic'
      userDic = fs.readFileSync(userDicpath, 'utf8')
      #console.log userDic

      #fstファイルの解析
      dict = text + userDic
      if dict?
        console.log "OK"
      editor = atom.workspace.getActiveTextEditor()
      Text = editor.getText()
      Text = Text.split(/\r\n|\r|\n/)

      for i in [0..Text.length-1]
        recogWord = Text[i].match(/.+RECOG_EVENT_STOP\|([^\x00-\x2b\x2d-\x7F]+)/)
        if recogWord?
          word = recogWord[1].split(',')
          for j in [0..word.length-1]
            if dict.indexOf(word[j]) == -1
              console.log word[j]
              console.log String(recogWord.input).indexOf(word[j])
              headIndex = String(recogWord.input).indexOf(word[j])
              range = new Range([i, headIndex],[i, headIndex + word[j].length])
              marker = editor.markBufferRange(range,invalidate: 'touch',false)
              editor.decorateMarker(marker, type: 'highlight', class: 'myunderline')
      console.log "finish"
      atom.notifications.addSuccess("finished checkDicionary")
      return

  ###
  range = new Range([line, 0],[line, 10])
  @marker = EDITOR.markBufferRange(range,invalidate: 'touch',false)
  EDITOR.decorateMarker(@marker, type: 'line', class: 'underline')
  EDITOR.decorateMarker(@marker, type: 'highlight', class: 'underline')
  console.log "test"
  ###

  #非文字列の数を返すメソッド，文字列を渡されると，Int文字数を返す
  numOfnonChar: (str) ->
    count = 0
    console.log str
    for i in [0..str.length-1]
      if escape(str.charAt(i)).length >= 4
          count += 1
          console.log count
    return Math.ceil(count)
#    return count

  # EditorIDを返すメソッド
  uriForEditor: (editor) ->
    # プラグインのURI 例:atom-handson-sum-preview://editor/1
    "dialogue-builder://editor/#{editor.id}"
