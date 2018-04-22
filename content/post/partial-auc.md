+++
date = "2017-12-23T00:59:39+09:00"
description = ""
draft = false
tags = []
title = "partial AUCでprecision重視の評価"

+++

機械学習の判別器を評価する際、F値やAUCはよく使われていると思います。
しかしながら、実応用の分野によっては、検出出来ないこと(false negative)よりも、誤検出(false positive)の方が問題視されることがよくあります。
そういったprecision重視にしたいケースで使える指標がpartial AUCです。
一般的には、false positiveに制約をもたせて用いるようです。AUCの面積を求める際に、そのfalse positive rateの下限値以上の部分のみ使います。

簡単に実装するため、scikit learnのaucのコードをオーバーライドして使っています。
```
import numpy as np
from sklearn.metrics import roc_auc_score, roc_curve, auc
from sklearn.metrics.base import _average_binary_score

# method overriding
def roc_auc_score(y_true, y_score, average="macro", sample_weight=None, max_fpr=None):
    def _binary_roc_auc_score(y_true, y_score, sample_weight=None, max_fpr=max_fpr):
        fpr, tpr, tresholds = roc_curve(y_true, y_score, sample_weight=sample_weight)

        if max_fpr:
            idx = np.where(fpr <= max_fpr)[0]

            idx_last = idx.max()
            idx_next = idx_last + 1
            xc = [fpr[idx_last], fpr[idx_next]]
            yc = [tpr[idx_last], tpr[idx_next]]
            tpr = np.r_[tpr[idx], np.interp(max_fpr, xc, yc)]
            fpr = np.r_[fpr[idx], max_fpr]
            partial_roc = auc(fpr, tpr, reorder=True)

            # standardize result to lie between 0.5 and 1
            min_area = max_fpr**2/2
            max_area = max_fpr
            return 0.5*(1+(partial_roc-min_area)/(max_area-min_area))

        return auc(fpr, tpr, reorder=True)

    return _average_binary_score(_binary_roc_auc_score, y_true, y_score, average, sample_weight=sample_weight)
```

以下のような感じで試してみると、AUCが同じスコアであっても、precisionが高い方がpAUCでは比較的高い値になることが分かります。
よって、pAUCを指標に学習やパラメータチューニングを行えば、precision重視のものが出来上がります。

```
import matplotlib.pylab as plt
import numpy as np

y_true = np.array([0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0])
y_pred_each_fp = {
    "many": np.array([0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
    "few": np.array([1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0]),
    "no": np.array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0]),
}


MAX_FALSE_POSITIVE_RATE = 0.3

plt.figure(figsize=(17, 5))
for fi, (fp_type, y_pred) in enumerate(y_pred_each_fp.items()):
    plt.subplot(1, 3, fi+1)
    fpr, tpr, _ = roc_curve(y_true, y_pred)
    plt.plot(fpr, tpr, color='r', lw=2)
    plt.plot([0, 1], [0, 1], color='k', lw=1, linestyle='--')
    plt.plot([MAX_FALSE_POSITIVE_RATE, MAX_FALSE_POSITIVE_RATE], [0, 1], color='k', lw=1, linestyle='-.')
    plt.xlabel('false positive rate')
    plt.ylabel('true positive rate')
    plt.title("{fp_type} false positives (auc:{auc:1.2f}  pauc:{pauc:1.2f})".format(fp_type=fp_type,
        auc=roc_auc_score(y_true, y_pred), pauc=roc_auc_score(y_true, y_pred, max_fpr=MAX_FALSE_POSITIVE_RATE)))
```

![pauc](/images/post/pauc/pauc.png)

