# HELEN - Dialogue Interaction Editor for MMDAgent -

## HELEN とは

HELEN は、MMDAgentの対話シナリオファイル（fstファイル）を編集するための Atom エディタ用拡張パッケージです．

[MMDAgent公式サイト](http://www.mmdagent.jp/)  
[fstファイルとは？](https://qiita.com/m-masaki72/items/8695e7d13607007257c5)  
[Atom公式サイト](https://atom.io/docs)  

HELENでは主に以下の3つの機能を利用することができます．  
- fstファイル編集の補助（対話フローのグラフ表示、認識辞書の自動チェック等）
- MMDAgent のリアルタイムデバッグ（状態遷移をリアルタイム可視化、任意メッセージの送信）
- 動作ログによるフィードバック（MMDAgent の動作ログ → 解析 → 対話シナリオにフィードバック表示）

## 準備

### 動作環境

HELENを利用するために必要な環境は以下の通りです。
- [Atom](https://atom.io/)・・・Version1.37.0以降をあらかじめインストールしてください
- Windows10以降・・・リアルタイムデバッグ時に必要  
- マイク・・・MMDAgentの利用に必要です  

※リアルタイムデバッグは拡張された専用のMMDAgent（同梱）を使うため、現在は Windows10 のみサポートしています。  
※Windows以外の環境でもAtomが動作する環境であればリアルタイムデバッグ以外の機能は利用可能です．

### インストール手順
1. HELENをダウンロードして（約270MB） Atomのpackagesディレクトリ以下に展開します．デフォルトはWindowsでは C:\Users\***\.atom\packages以下です。zip をダウンロード・展開するか、直接 git clone してください。
3. Atomを起動します
4. Atomの Packages メニュー内に "HELEN" が表示されていることを確認します
5. 準備完了です

<!-- ## Demo -->

## HELEN用ウィンドウを開く

Atomで fstファイルを開いた状態で以下の操作のどちらかを行うことで、その fst に対するHELEN用ウィンドウを右ペーンに開けます。。

- メニューの Packages → HELEN → Open HELEN Window 
- `Ctrl + Alt + shift + g`

HELEN用ウィンドウは（"1 DialogueBuilder") のような名前になっています。複数の fst を編集する場合、カレントの切り替えでは自動的に切り替わりませんので、fstのバッファごとに個別にHELEN用ウィンドウを作成してください。

![Draw Graph](./manual/5.png)  

## 機能１：fstファイルの編集補助

### グラフ描画

FSTをグラフィカルに表示するには、HELEN用ウィンドウの `MAKE_GRAPH`ボタンを押します。

- 状態あるいは遷移の上にカーソルを置くと内容がポップアップ表示されます
- 同一状態間に複数の遷移がある場合は１つにまとめて表示されます。
- 状態をクリックすると、対応する fst の行へジャンプできます。 
- fst ファイルを変更した場合、保存時にグラフが自動更新されます
- グラフが大きい場合は「BIG」「SMALL」ボタンで拡大・縮小できます． 

![Draw Graph](./manual/5.png)  


### フィールドの桁揃え

fst のバッファ上で **Insert TAB**: `Ctrl + Alt + shift + t` を実行することで、fstのフィールドごとに自動的桁揃えが行えます。

![Insert Tab](./manual/2.png)

### 認識辞書のチェック

**checkDictionary**: `*Ctrl + Alt + shift + d*` は音声認識辞書の自動チェックです。 fst 中で音声認識結果として捉える単語 (`RECOG_EVENT_STOP` の引数) の各引数について、内蔵の音声認識用辞書をチェックし、辞書にない未知語を強調表示します． 
強調された単語は[単語辞書に追加](https://mmdagent.wordpress.com/2013/01/18/adding-recognition-words/)するようにしましょう．  

![check Dictionary](./manual/10.png)


## 機能２：MMDAgent のリアルタイムデバッグ 

この機能を利用するためには，以下の動作が必要になります．

### リアルタイムデバッグの準備
1. MMDAgentのコンテンツを作成します．
2. 手順1で作成したコンテンツのディレクトリ内にあるmdfファイルをドラッグします
3. 手順2でドラッグしたmdfファイルを，ダウンロードしたディレクトリ内にある`tools/mmdagent_exe/MMDAgent.exe`にドロップします
4. MMDAgentが起動します
5. 手順1～4までの動作を行ったときと同じpcでAtomを起動します
6. Atom上で作成したコンテンツのfstファイルを開きます
7.  (*Ctrl + Alt + shift + g* ) を入力してグラフ描画タブを開くと準備完了です

### 注意事項
- MMDAgentのコンテンツ作成については[こちら](https://mmdagent.lee-lab.org/?p=460&lang=ja)．[公式サイト](http://www.mmdagent.jp/)からサンプルコンテンツをダウンロードすることも可能です．
- 現在この機能は`Windowsでのみ利用可能`です．
- 手順3で使用するファイルは，MMDAgent公式サイトで公開されている`MMDAgent.exe`ファイルではなく，HELENに同梱されている専用の
`MMDAgent.exe`ファイルが必要です．
- 一定時間起動し続けると不具合が発生することがあります．その際はエディタとMMDAgentをリロード(*shift + r* )してください．

### 状態遷移のリアルタイム可視化

MMDAgentを起動したら，最初に下記の `text Following` のチェックマークをONにすることでフォローモードを起動できます．  
（上手く機能しない場合はもう一度MAKE_GRAPHボタンをクリックしてグラフを更新してください．）  
起動中のMMDAgentの対話シナリオの現在状態番号が随時読み取られ、対応するエディタ上のfstの状態が強調表示されます。
![Follow mode](./manual/6.png)   

現在状態はグラフ上でオレンジ色で表示されます。現在状態はMMDAgentの動作をリアルタイムに反映して移動していきます（下図の赤枠）。
チェックマークをOFFにすると動作を停止します。
![Debug](./manual/8.png)  

### 任意メッセージの送信

以下の赤い四角で囲まれた部分にMMDAgentのコマンドを入力して右の「SEND_MESSAGE」をクリックすることで、起動中のMMDAgentに対して任意メッセージの送信が行えます。
![Send Command](./manual/4.png)

## 機能３：動作ログによるフィードバック

HELENでは，MMDAgentの動作ログから抽出した状態滞在時間等の情報を重ねて表示することができます。
これにより、実際の利用状況をフィードバックしながらFSTを編集することができます。

本機能は下記の学会で発表する予定の機能です：

> 森 雅希、李 晃伸．「[音声対話コンテンツ循環環境を実現するための対話シナリオのプロファイル自動収集およびフィードバック](https://confit.atlas.jp/guide/event/jsai2019/subject/3L4-OS-22b-01/tables?cryptoId=)」
> 

動作ログは MMDAgent の標準出力を保存する方法のほか、[Pocket MMDAgent](https://mmdagent.lee-lab.org/) を用いてサーバ経由で取得することも可能です。
ログの作成方法やサーバの仕様など詳細は[こちら](https://mmdagent.lee-lab.org/?p=576&lang=ja)をご覧ください．

### 準備
1. MMDAgentのコンテンツを作成します．  
2. MMDAgent を動作させ、動作ログを記録します。記録の方法はいくつかあります。
- MMDAgent の .mdf ファイルに `log_file=ファイル名` を記述すると、動作ログがそのファイルに記録されます
- [Pocket MMDAgent](https://mmdagent.lee-lab.org/?p=576&lang=ja)の機能を用いてサーバにログをアップロードする
3. 適当なディレクトリを作成し、動作ログをそこに置きます。拡張子は .txt としてください。また動作ログ以外の .txt を置かないでください。
4. HELENを解凍してできたディレクトリ内にある`tools/log_server/make_profile.py`を、3. のディレクトリにコピーします
5. 4. でコピーした先のディレクトリに移動し，`./make_profile.py` を実行します。
6. 解析結果のプロファイルが `「MMDAgent.profile」` というファイルに保存されます。これを、作成したコンテンツのfstファイルがある場所と同じディレクトリに移します。
7. `MMDAgent.profile`の「MMDAgent」の部分を「\*\*\*.fst」の\*\*\*と同じ名前にします
8. 準備完了です

### 注意事項
- pythonのバージョンは3.7.3で確認しています

### 機能一覧
手順1～8までの処理の後，HELENのビューアを更新すると以下のような強調表示が可能となります
![Profile show](./manual/userage.png)  
また，グラフ上の各状態をクリックするとその状態での利用状況を表示させることができます  
認識単語はその状態で認識された単語が表示されます  
![Profile data](./manual/11.png)

## プロファイル表示の凡例
![Profile show ex](./manual/判例.png)


## Licence
MIT

## Author
[Akinobu Lee](https://www.slp.nitech.ac.jp/)，[Masaki Mori](https://github.com/m-masaki72)，[Yuuki Yabusaki](https://www.slp.nitech.ac.jp/~yabusan16/) at Nagoya Institie of Technology, Japan.