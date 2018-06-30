+++
date = "2018-02-20T00:00:00+09:00"
description = ""
draft = false
tags = []
title = "pythonの各種使い方をオフラインで確認する方法"
+++

インターネットから隔離されていたりや書籍が持ち込みできないような環境で、プログラミングをすることがあった。
こういうときのために、各種ライブラリの使い方などをオフラインでも確認できるようにしておくと良い。

## 各種ライブラリのヘルプ確認の仕方

例えば、scikit-learnのkmeansクラスタリングの使い方を調べたいとき。
一番上から順に探していく。

```
> import sklearn
> help(sklearn)
...
PACKAGE CONTENTS
    ...
    cluster (package)
...
```

```
> import sklearn.cluster
> help(sklearn.cluster)
...
PACKAGE CONTENTS
    ...
    k_means_
...
```

```
> import sklearn.cluster.k_means_
> help(sklearn.cluster.k_means_)
class KMeans(sklearn.base.BaseEstimator, sklearn.base.ClusterMixin, sklearn.base.TransformerMixin)
     |  K-Means clustering
     |
     |  Parameters
...
目的の使い方にたどり着いた
```


## jupyter notebook上でのやり方

```
> import pandas as pd
> pd.read_csv?
```

下部にヘルプ用のウインドウが別途表示されるので、若干見やすい（？）


