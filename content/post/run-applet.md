+++
date = "2017-02-26T03:56:14+09:00"
description = ""
draft = false
tags = ["Java", "Mac"]
title = "ブラウザで動作出来なくなったJavaアプレットをローカルで動かす"

+++

昔作って公開していたJAVAアプレットを発掘したものの、
ブラウザやJavaのセキュリティ設定をいじっても安定して表示することが出来ませんでした。
例外サイトとかに追加しても、ネットワーク切り替えなどちょっとしたきっかけで実行不能に...

いろいろ調べた結果、Macの場合、以下のような感じでダウンロードしてから実行することで、
安定して動作させることが出来ました。
公開は諦めて、とりあえず身近な人に見せるだけなら、これで良さそうです。

```
$ wget --no-parent -r "javaアプレットのファイル一式が入ったディレクトリXXXXのURL"
$ cd XXXX
$ appletviewer XXXX/main.html
```

Javaアプレット、一時期はまってたなぁ...
