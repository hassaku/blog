+++
date = "2017-03-04T04:08:51+09:00"
description = ""
draft = false
tags = ["python", "machine learning"]
title = "hyperoptでパラメータサーチ"

+++

機械学習におけるモデルのハイパーパラメータ探索は、その後のモデル評価を正当に行うことにも繋がる、重要な作業です。
近年ではRandom SearchやGrid Search、GA等の各種最適化手法よりも、色々と優れた手法が提案されているらしく、
手軽に使えるようなライブラリも整備されています。
パラメータ探索技術というと、応用範囲が広く、効果が見えやすいため、手軽に使えて効率的な手法があれば、積極的に使っていきたいところです。
その中でもhyperoptというライブラリが、kaggleとかでよく使われているという話を見かけて、試しに使ってみました。

中身については、色々Blogや論文が見つかるのですが、
Bayesian Optimization -> Sequential Model-based Algorithm Configuration (SMAC) -> Tree-structured Parzen Estimator (TPE)
のように進化してきたTPEという手法が使われているようです。
Bayesian Optimizationのアプローチは、直感的にも効率良さそうなので、その進化系なら期待できます。

[Hyperopt]
(http://hyperopt.github.io/hyperopt/)


## 簡単な使い方

以下のような感じで、簡単に記述出来て、手軽に取り入れられそうです。

```
#!/usr/bin/env python
# encoding: utf-8

import os
import sys

import matplotlib.pyplot as plt
import numpy as np
from hyperopt import fmin, tpe, hp, Trials

# パラメータの探索範囲。指定方法は離散値や連続値などに応じて色々ある。
# https://github.com/hyperopt/hyperopt/wiki/FMin#21-parameter-expressions
hyperopt_parameters = { 'x': hp.uniform('x', -30, 30) }

# 最小化したい目的関数。正解との誤差とか。
def objective(args):
    return np.sin(args['x']) / args['x']

# 探索中の進行状況を記録
trials = Trials()

# パラメータサーチの実行
best = fmin(objective,  hyperopt_parameters, algo=tpe.suggest, max_evals=300, trials=trials)

# 目的関数を最小にするパラメータ
print best
```

## パラメータサーチの様子を表示


```
# 上記コードの続き

x_hisotry = np.ravel([t['misc']['vals']['x'] for t in trials.trials])
objective_history = trials.losses()

fig = plt.figure(figsize=(16, 8))
cm = plt.get_cmap('jet')

PLOT_NUM = 5

for i, hist_num in enumerate(np.linspace(50, 300, PLOT_NUM)):
    cmap_cycle = [cm(1. * h/ (hist_num - 1)) for h in range(int(hist_num) - 1)]

    ax = plt.subplot(2, PLOT_NUM, i + 1)
    ax.set_color_cycle(cmap_cycle)
    ax.plot(np.arange(-30, 30, 0.1), function(np.arange(-30, 30, 0.1)), alpha=0.2)
    for j in range(int(hist_num)  - 1):
        ax.plot(x_hisotry[j], objective_history[j], '.')
    ax.set_title('times: {times}'.format(times=int(hist_num)))
    ax.set_ylim([np.min(objective_history) - 0.1, np.max(objective_history) + 0.1])
    ax.set_xlim([-30, 30])
    if i == 0:
        ax.set_ylabel('y')

    plt.subplot(2, PLOT_NUM, PLOT_NUM + i + 1)
    plt.hist(x_hisotry[:hist_num], bins=50)
    if i == 0:
        plt.ylabel('histogram of x')
    plt.xlabel('x')
```

![hyperopt](/images/post/hyperopt/hyperopt.png)

右に進むに連れて、パラメータ探索が進んでいく様子を表しています。
上段の図が、目的関数と探索点の描画です。x=0の点が求めたいパラメータとなります。
下段の図が、各探索点のヒストグラムを描画しているのですが、探索が進むにつれて、
目標のパラメータ付近を効率的に探索している様子が分かります。

