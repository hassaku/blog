+++
date = "2019-05-03T10:00:00+09:00"
description = ""
draft = false
tags = ["python"]
title = "データ分析コンペとかによくやる作業"
+++

# 大きいデータの読み込み

daskを使って並列処理

```
import dask.dataframe as ddf
import dask.multiprocessing

df = ddf.read_csv('train_data.csv')
df = df.compute(get=dask.multiprocessing.get)
```

# EDA

データに関する簡単な統計情報確認

```
import pandas_profiling as pdp
pdp.ProfileReport(df)
```

データの相関を確認

```
import seaborn as sns
sns.pairplot(df, hue="target", diag_kind="kde")
```

# 前処理

- 欠損値の補完
- 外れ値の削除
- カテゴリ変数の扱い
  - one hot encoding （次元増える系）
    - どれかひとつだけ1になるようなスパースなベクトル表現
  ```
  city_dummies = pd.get_dummies(df["city"], prefix="city")
  df.drop(["city"], axis=1, inplca=True)
  df = df.join(city_dummies)
  ```
  - count encoding （次元増えない系）
    - カテゴリ変数の出現回数（あるいは率）を値とするような表現
  ```
  df['count_city'] = df.groupby('city')['target'].transform('count')
  ```
- 並列処理
  ```
  import numpy as np
  import pandas as pd
  #import multiprocessing as mp  # impossible to use lambda with pickle
  import pathos.multiprocessing as mp  # dill is used inside instead of pickle.

  def split_parallel(df, num_split, map_func):
      with mp.Pool(num_split) as p:
          df_split = np.array_split(df, num_split*2)
          result = p.map(map_func, df_split)
      return pd.concat(result)

  NUM_PARALLELS = 3
  df["new_col"] = split_parallel(df, NUM_PARALLELS, lambda x: x["col1"] + x["col2"])
  ```

# CV

```
from sklearn.model_selection import StratifiedKFold

cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=123)
X_train = np.zeros(20, 5)
y_train = np.zeros(20)

for train_idx, valid_idx in cv.split(X_train, y_train):
    print(train_idx, valid_idx)
    ...
    losses.append(loss)

cv_loss = np.mean(losses)
```

# 結果のアンサンブル

```
res1 = pd.read_csv('../method1/submission.csv')
res2 = pd.read_csv('../method2/submission.csv')
res3 = pd.read_csv('../method3/submission.csv')

b1 = res1.copy()
col = res1.columns

col = col.tolist()
col.remove('id')
for i in col:
    b1[i] = (2 * res1[i]  + 2 * res2[i] + 4 * res3[i]) / 6.0

b1.to_csv('submission.csv', index=False)
```

# Jupyter Notebook上でCSVの確認とダウンロード

実行するとディレクトリ内のファイル一覧が表示されて、クリックすればダウンロード出来るはず

```
from IPython.display import FileLinks
FileLinks(DATA_DIR)
```
