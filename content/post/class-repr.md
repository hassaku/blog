+++
date = "2017-03-04T04:07:38+09:00"
description = ""
draft = false
tags = ["python"]
title = "インスタンスを表す文字列を分かりやすくする"

+++

ログとかにインスタンスの内容をダンプしたりするとき、つい適当にprintとかlogger.debugしても、
標準では、インスタンスの内容をスマートに分かりやすく表示してくれたりはしないようです。

そのため、デバッグをしやすくするためにも、以下のような感じで\__repr__をオーバーライドしておくと、
分かりやすくなって便利だったりします。

## reprを定義しない場合

```
class MyClass(object):
  def __init__(self):
    self.attr1 = 123
    self.attr2 = 456

mc = MyClass()
print(mc)  # => <__main__.MyClass object at 0xXXXXXXXXXX>
```

## reprを定義する場合

```
class MyClass(object):
  def __init__(self):
    self.attr1 = 123
    self.attr2 = 456

  def __repr__(self):
    return ", ".join("%s: %s" % item for item in vars(self).items())

mc = MyClass()
print(mc)  # => attr2: 456, attr1: 123
```

ちょっとしたTipsでした。



