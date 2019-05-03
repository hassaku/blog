+++
date = "2019-02-25T10:00:00+09:00"
description = ""
draft = false
tags = ["python", "nlp"]
title = "word vectorのような読み込みが重たいやつをWebAPI化して軽量化"
+++

word vectorとかメモリをどデカく使うようなやつは、毎回スクリプトを起動する際に読み込みに時間がかかって辛い。
そういうのは、極力別のプロセスにして、適当にAPIとか生やして連携するようにしておくと楽チンなので良くやるパターン。

以下は、単語ベクトルを返してくれるAPIを作った例。Flask使うとコードもシンプルに実現出来るので良い。

```
# coding: utf-8

import numpy as np
import gensim
from flask import Flask, jsonify, request
import json

PRETRAINED_W2V_PATH = './model.bin'

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False

model = gensim.models.KeyedVectors.load_word2vec_format(PRETRAINED_W2V_PATH, binary=True)  # 超時間かかる処理

@app.route('/word_vector', methods=['GET'])
def word_vector():
    word = request.args.get('word')
    vector = np.array(model[word]).astype(float).tolist()
    return jsonify({'vector': vector}), 200


if __name__ == "__main__":
    app.debug = True
    app.run(host='0.0.0.0', port=8888)
```

以下のような感じで単語ベクトルの値をjsonで返してくれる。pythonのスクリプトからはrequestsとかで簡単に取得して扱えるはず。

```
$ curl "http://0.0.0.0:8888/word_vector?word=テスト"
{
  "vector": [
    0.029713749885559082,
    -0.6024296283721924,
    0.9723357558250427,
    -1.1497808694839478,
    1.3764394521713257,
...

```

例えば、連続動作しているようなエージェントシミュレータなんかにも、似たような感じでAPI生やして、インタラクションさせることが出来る。


