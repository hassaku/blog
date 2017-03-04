+++
date = "2016-04-01T00:35:40+09:00"
description = ""
draft = false
tags = ['python']
title = "exception-slackerというライブラリをPyPIに登録した"

+++

https://github.com/hassaku/exception-slacker

importして、Slackのtokenや投稿チャンネルなどを環境変数でセットしておけば、例外が発生した際に、以下のような感じでSlackへ投稿します。

![exception_slacker](/images/post/exception_slacker/exception_slacker.png)

時間のかかるプロセスなどを実行している時に、いちいちコンソールをチェックする手間が省けるので、個人的に便利だと思って公開しました。
