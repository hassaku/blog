+++
date = "2018-04-23T00:00:00+09:00"
description = ""
draft = false
tags = ["python"]
title = "ターミナル上で１行の簡易グラフ"
+++

データ処理などしていると、処理中の状況を確認するのに、数値や文字列よりもグラフの方が適していることが多い。
ただ、そのためだけにGUIなどを用意するのは大変だし、出来ればターミナル上で表示したい。
というわけで、ログなど混ぜて、以下のような感じで、簡易的にグラフ描くと便利。

```
$ cat simple_plot.py

# coding: utf-8

import numpy as np

TICKS = u'_▁▂▃▄▅▆▇█'

def ascii_plot(ints, max_range=None, min_range=0, width=40):
    assert len(ints) >= width

    ints = np.array(ints, dtype=int)
    ints = ints[:int(len(ints)/width)*width]
    ints = np.nansum(np.reshape(ints, (int(len(ints)/width), width)).T, axis=1)

    if not max_range:
        max_range = max(ints)
    if not min_range:
        min_range = min(ints)

    step_range = max_range - min_range
    step = (step_range / float(len(TICKS) - 1)) or 1
    return u''.join(TICKS[int(round((i - min_range) / step))] for i in ints)


if __name__ == "__main__":
   print(ascii_plot(range(10) + range(10, 0, -1), width=20))
```

```
$ python simple_plot.py
_▁▂▂▃▄▅▆▆▇█▇▆▆▅▄▃▂▂▁
```
