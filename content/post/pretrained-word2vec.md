+++
date = "2017-02-26T02:27:30+09:00"
description = ""
draft = false
tags = ["NLP", "対話システム"]
title = "学習済みword2vecモデルを調べてみた"

+++

日本語の自然言語処理で分散表現を使おうと思った場合、まず頭に浮かぶのはword2vecだと思います。
特に分散表現自体の精度とかには興味がなく、それを使った対話システムを作りたいだけだったりするのであれば、
データクレンジングや学習には結構時間もかかるので、学習済みの公開モデルを使わせていただくのが手っ取り早そうです。


(単語ベクトルの準備に手間取り、モチベーション低下に繋がる悪い例：[対話システムを作りたい！【準備編１】]
(http://blog.hassaku-labs.com/post/dialogue_system1/))

調べてみると、よく出来ていそうな公開モデルを２つ見つけたので、その利用方法と気になるベクトル次元数と単語数を調べてみました。
なお、どちらもWikipedia日本語版を学習元にしているようです。

word2vecを使うには、以下のバージョンのgensimを利用します。
```
$ pip freeze | grep gensim
gensim==1.0.0
```

## 白ヤギコーポレーションのモデル

[word2vecの学習済み日本語モデルを公開します]
(http://aial.shiroyagi.co.jp/2017/02/japanese-word2vec-model-builder/)

```
>>> from gensim.models import word2vec
>>> model = word2vec.Word2Vec.load('./shiroyagi/word2vec.gensim.model')
>>> model[u'ニュース'].shape
(50,)
>>> model.corpus_count
1046708
```

## 東北大学 乾・岡崎研究室のモデル

[日本語 Wikipedia エンティティベクトル]
(http://www.cl.ecei.tohoku.ac.jp/~m-suzuki/jawiki_vector/)

```
>>> from gensim.models import KeyedVectors
>>> model = KeyedVectors.load_word2vec_format('./tohoku_entity_vector/entity_vector.model.bin', binary=True)
>>> model[u'ニュース'].shape
(200,)
>>> len(model.vocab)
1005367
```

#### gensimが1.0.0未満の場合（ただしシロヤギさんのモデルは1.0.0以上が必要のようです）
```
>>> from gensim.models import word2vec
>>> model = word2vec.Word2Vec.load_word2vec_format('./tohoku_entity_vector/entity_vector.model.bin', binary=True)
```

## まとめ

同じ日本語Wikipediaを学習しているので、ボキャブラリの数は大体同じく約100万程度と十分そうな感じです。
ベクトルの次元数については、白ヤギさんのモデルの方が小さく、動作は軽そうです。
一方で、東北大学のモデルの方が、単語の表現力は高そうなので、色々検証レベルでは色々と無難な気がします。
実はもう少し高次元での処理をしたいので、更にこれをスパース（出来れば２値ベクトル）に変換するようなこと
（こういうやつ [Sparse Overcomplete Word Vector Representations] (http://www.manaalfaruqui.com/papers/acl15-overcomplete.pdf) ）
をやりたいのですが、それはまた次回にでも。。



