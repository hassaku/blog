+++
date = "2016-01-24T02:26:21+09:00"
draft = false
title = "対話システムを作りたい！【準備編１】"
tags = ["NLP", "対話システム"]
+++

2016年はVRとか流行りそうで、仮想空間での生活を妄想してしまう今日このごろ。
でも、今のままだとNPCがちゃんと自然に会話してくれない気がして微妙なんですよね。。。そこで、既存技術の延長で、どれくらいの日本語対話が可能か、ちょっと自分でも作ってみたくなりました。

自然言語処理をちゃんと勉強したことはないけれど、脳型情報処理アプローチでいくとしたら、結局はベクトル時系列データの処理なのかな？って思います。とりあえず、色々試してみましょう。

たぶん、進め方はこんな感じ。

1. 単語のベクトルデータ化（言語コーパス？）
2. 対話データのベクトル時系列データ化（対話コーパス？）
3. 会話時系列データにおける応答時系列データの予測学習
4. 学習結果を用いた対話システム構築

というわけで、今回は１の言語コーパス作成について。単語を入力とし、N次元ベクトルに変換することを目標。似たような単語は近くに配置されるような変換が好ましい（分散表現だ！）。

# 言語コーパスをWikipediaの記事から作成

## wikipediaの日本語記事をダウンロード

```
$ curl -O http://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz
```

## mecabをインストール

単語の分かち書きへ変換するためのツールです。macならbrewでインストール可能。

```
$ brew install mecab
$ brew install mecab-ipadic
```

### 新語用辞書をインストール

最近の単語は、brewでインストールされた辞書には含まれていないので、新語に対応した辞書に更新します。

```
$ git clone --depth 1 git@github.com:neologd/mecab-ipadic-neologd.git 
$ cd mecab-ipadic-neologd/
$ ./bin/install-mecab-ipadic-neologd -n   # 辞書updateも同じコマンド
$ echo `mecab-config --dicdir`"/mecab-ipadic-neologd"  # 実行時指定のパスを調べる
/usr/local/lib/mecab/dic/mecab-ipadic-neologd
```

### （参考）新御用辞書有無を確認

```
$ pip install mecab
$ python
In [1]: import MeCab
In [2]: mecab_org = MeCab.Tagger("-Owakati")
In [3]: mecab_new = MeCab.Tagger("-Owakati -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd")
In [4]: print mecab_org.parse("電力自由化がはじまる")
電力 自由 化 が はじまる 
In [5]: print mecab_new.parse("電力自由化がはじまる")
電力自由化 が はじまる 
```

なんとなく最近ニュースとかで出てくるような単語を分かち書き出来ている（気がします）。

## wikipediaを分かち書き

各単語に分かち書き変換します。

### HTMLタグとかを取っ払って文章だけに変換

```
$ echo 'gem "wp2txt"' >> Gemfile 
$ bundle
$ bundle exec wp2txt --input-file jawiki-latest-pages-articles.xml.bz
$ ls wp2txt/  # 変換結果
$ rm jawiki-latest-pages-articles.xml.bz # 不要だから消す
$ cat wp2txt/jawiki-latest-pages-articles-* > corpus.txt # 変換結果を一つのファイルに連結
```

とても時間かかります...
記号除去とかした方が良いのかどうか、今のところ謎です。

### 新語辞書使って分かち書き

```
$ mecab -Owakati -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd corpus.txt > corpus_wakati.txt
```

とても時間かかります...

## word2vecによるベクトル化

今後pythonで実装することもあり、gensim使います。

```
$ pip install gensim
```

### utf-8に変換

しないとword2vecのときに、文字コードについて怒られたので...

```
$ iconv -c -t UTF-8 < corpus_wakati.txt > corpus_wakati_utf-8.txt 
```

### 学習

以下のpythonコードを実行します。次元は適当に中程度としました。

```
$ vi word2vec_train.py
# coding: utf-8
from gensim.models import word2vec
import sys, logging, string, codecs

logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

# 学習（400次元だと４コアで約３時間...）
sentences = word2vec.Text8Corpus("corpus_wakati_utf-8.txt")
model = word2vec.Word2Vec(sentences, size=400, workers=4)
# モデルの保存
model.save("w2v_model_%d_dims" % dims)
```

### 検証

#### モデルの読み込み

```
$ pyton
In [1]: from gensim.models import word2vec
In [2]: model = word2vec.Word2Vec.load("./word2vec_models/w2v_model_%d_dims" % 400)
```

#### ベクトル空間上で近い単語を探す

動作確認です。

```
In [3]: most_similar = model.most_similar(positive=[u'サッカー'])[0]
In [4]: most_similar[0]
ラグビー
In [5]: most_similar[1]
0.663492918015  # コサイン距離？
```

#### ベクトル取得

このベクトルに対して今後処理していくことになります。

```
In [1]: vector = model[u'サッカー']
array([  2.69545317e-01,  -1.99663490e-01,   9.52050760e-02,
         2.16732353e-01,   1.97090670e-01,  -1.90409079e-01,
         ...
In [2]: vector.shape
(400,)
In [3]: vector.min()
-0.71880466
In [4]: vector.max()
0.75658286
```

#### ベクトルから単語を探す

処理結果のベクトルから単語を復元する手段も確認しておきます。

```
In [5]: vector[0:10] = 0.0  # 適当に変更  
In [6]: for cname in [candidate[0] for candidate in model.most_similar(positive=[vector], topn=3)]:
            print cname
サッカー
ラグビー
フットサル
```

## おわり

ひとまず今回はここまで。単語をベクトル化したことにより、文章をベクトル時系列データとして扱うことが出来、色々な機械学習手法が適用可能になりました。
次回以降色々試してみたいと思います。

-----

# おまけ

この時点でも色々作って遊べますね。例えば、以前作った絵文字サジェスト用hubotでは、キーワードに近しい、絵文字キーワードを引っ張ってきて候補を表示してました。Githubとかだと、標準でも絵文字キーワードを入力すると、続きをサジェストしてくれるものの、そもそものキーワードが思いつかなかったりするので、そういうときに便利です :)

![word2emoji.jpg](/images/post/dialogue_system1/word2emoji.jpg)

