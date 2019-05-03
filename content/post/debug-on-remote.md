+++
date = "2019-02-25T10:00:00+09:00"
description = ""
draft = false
tags = ["python"]
title = "IDE使えないときの例外時デバッグ"
+++

IDEが使える状況であれば、簡単にデバッガーを使えると思うが、そうでない環境でデバッグしたくなることもある。
printデバッグも辛いので、以下のような感じで例外時等にpython debuggerを起動出来ると便利。

```
import sys

def hook(type, value, tb):
   if hasattr(sys, 'ps1') or not sys.stderr.isatty():
      sys.__excepthook__(type, value, tb)
   else:
      import traceback, pdb
      traceback.print_exception(type, value, tb)
      print()
      pdb.pm()

sys.excepthook = hook
```

というのを適当なところにdebug.pyとして置いておいて、デバッグしたいコード実行時にimportしておくだけ。
例外が起きるとデバッガが起動し停止するので、そのときの変数の値などを表示したり調べると良い。

不必要に毎回デバッガ起動すると面倒なので、普段はimport行をコメントアウトしておくこと。

よく使うコマンドは以下のとおり。

- w
  - where. スタックトレースを表示する。
- u
  - up. スタックを一つ上に移動
- d
  - down. スタックを一つ下に移動
- l [first, last]
  - list. 現在のソースコード表示。fist, lastを指定可能。
- p [target]
  - print. 変数等を表示。
- c
  - continue. 次のブレークポイントに当たるまで実行
- s
  - step. 現在の行を実行 (関数の中に入る）
- n
  - next. 現在の行を実行 (関数の中に入らない）
- q
  - quit. デバッガを終了

