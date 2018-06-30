+++
date = "2018-01-23T00:00:00+09:00"
description = ""
draft = false
tags = ["slack", "ruby"]
title = "Slackのメッセージ収集"
+++

Slackに投稿されたメッセージを収集する方法についてのメモ

## データexport

https://xxxx.slack.com/services/export

exportが完了すると、slack上でbotから通知くる

## ユーザID取得

```
$ curl https://slack.com/api/users.list\?token\=YOUR_SLACK_TOKEN
```
最新のSlack Token取得方法は色々記事が挙がっているのでググること

## 一ヶ月のユーザの発言を収集する

```
$ cat show_messages.rb

require 'json'

user = "USER_ID"
year = 2016
month = 2
days = 29

days.times do |day|
  date = "%d-%2d-%02d" % (year, month, day + 1)
  export_file = "./#{date}.json"
  next unless File.exist?(export_file)
  puts "\n----- #{date} -----"

  json_data = open(export_file) do |io|
    JSON.load(io)
  end

  json_data.each do |json|
    puts "#{Time.at(json['ts'].to_i)}: #{json['text'].gsub(/\n+/, ' ')}" if json["user"] == user
  end
end

$ ruby show_messages.rb
```

