+++
date = "2019-05-01T10:00:00+09:00"
description = ""
draft = false
tags = ["google apps script"]
title = "GASで作る日常ツールあれこれ"
+++

# 【基本】Google Apps Scriptの作り方

- スプレッドシート作成
- ツール - スクリプトエディタ

# 【基本】WebAPI化の共通事項

- doPostという関数
- 公開 > webアプリケーションとして導入 を選び公開
- コードを修正した場合、バージョン に 新規作成 を選択する必要がある。
- アクセス出来るユーザは全員（匿名）にしておくこと

# 【基本】簡単なデータストア先として活用

WiFi接続のセンサモジュールとか、ちょっとしたものからデータを記録していきたいときに利用

```
var sheet = SpreadsheetApp.openById(URLのところに表示されるID).getSheetByName(シート名);

function doPost(e) {
  var array = [e.parameter.timestamp, e.parameter.sensor_id, e.parameter.value];
  sheet.appendRow(array);
}
```

```
$ curl -X POST -F "timestamp=`date "+%Y%m%d %H:%M:%S"`" -F 'sensor_id=1234' -F 'value=5678' 公開時に表示されるURL
```

スプレッドシートにデータが追記されていくので、それをCSV化してデータ分析するなり、簡単に可視化するなり。

# 【基本】Slack通知の共通部分

以下の各事例でも頻繁に使われてる

```
/*
リソース - ライブラリから以下を追加
- SlackApp: M3W5Ut3Q39AaIwLquryEPMwV62A3znfOO
- Underscore: MGwgKN2Th03tJ5OdmlzB8KPxhMjh3Sh48
- Moment: MHMchiX6c1bwSqGM1PZiW_PxhMjh3Sh48
*/

var _ = Underscore.load();
var TOKEN = "SLACK_TOKEN";

var slackApp = SlackApp.create(TOKEN);

function getChannelId(name) {
  // チャンネル名から通知に必要なIDを取得
  var channel = _.findWhere(slackApp.channelsList().channels, {name: name});
  if (_.isEmpty(channel)) {
    throw new Error(name + " is not found");
  }
  return channel.id
}

function postMessage(channel_name, message) {
  // 任意のメッセージを通知
  var channelId = getChannelId(slackApp, channel_name);

  slackApp.chatPostMessage(channelId, message, {
    username : "bot",
    icon_emoji : ":mega:"
  });
}

```

# Googleドキュメント・スライド定期複製

定例ミーティングなどで、毎回人手で過去分議事録をコピーして、事前メモ用ドキュメントを作成しているケースがあったので自動化した。
コピー元は、前回分とかではなく、毎回決まったテンプレートとかを指定しても良い。

```
function createCopy(fileId, fileName) {
  // 最新の日付を付けたコピーを作成
  var date = new Date();
  date.setDate(date.getDate());
  var formattedDate = Utilities.formatDate(date, "JST", "yyyyMMdd");
  var f = DriveApp.getFileById(fileId);

  f = f.makeCopy(formattedDate + "_" + fileName);
  return f.getUrl();
}

function latestFileId(folderId, fileName) {
  // 前回分のファイルを取得
  var folder = DriveApp.getFolderById(folderId);
  var contents = folder.getFiles();

  var latest = 0;
  var latestFileId = 0;

  while(contents.hasNext()) {
    var file = contents.next();
    var name = file.getName();

    if (!name.match(new RegExp("^.*_" + fileName +"$"))) {
      continue;
    }

    // 20190501_XXXXX みたいな名称を想定
    var updatedAt = parseInt(name.slice(0, 10), 10);
    var fileId = file.getId()

    if(latest < updatedAt) {
      latest = updatedAt;
      latestFileId = fileId;
    }
  }
  return latestFileId;
};

function main() {
  var channel_name = "通知したいSlackチャンネル名";
  var fileName = "XXXXX";
  var folderId = "Google Driveで対象ファイルが配置されているフォルダのURLに含まれるID";

  var fileId = latestFileId(folderId, fileName);
  var url = createCopy(fileId, fileName);
  postMessage(channel_name, "XXXXXのアジェンダを作成しました。 -> " + url);
}
```

編集 - 現在のプロジェクトのトリガーからmain指定すれば、定期実行させることが出来る

# ドライブ更新通知

ドライブにファイルが追加されたりしたときにSlack通知

予めconfigというシートにfolder_id, slack_channel, messageの列を作っておき、
- floder_id
  - Google Driveの対象フォルダのURLに含まれるID
- slack_channel
  - 通知したいSlackチャンネル名
- message
  - 通知時のメッセージ
を定義しておくこと。複数可。

また、トリガは１分ごと実行に設定。

```
var INTERVAL_MINUTES = 1;  // １分以内に更新されたやつを対象とする

function checkFolder(folderId, channelName, message) {
  var folder = DriveApp.getFolderById(folderId);
  var now = Moment.moment();
  var updates = [];

  var files = folder.getFiles();
  while (files.hasNext()) {
    var file = files.next();
    var updatedAt = Moment.moment(file.getLastUpdated());
    var elapsedMinutes = (now - updatedAt) / 1000 / 60

    if (elapsedMinutes < INTERVAL_MINUTES) {
      updates.push(file.getName());
    }
  }

  var folders = folder.getFolders();
  while (folders.hasNext()) {
    var folder = folders.next();
    var updatedAt = Moment.moment(folder.getLastUpdated());
    var elapsedMinutes = (now - updatedAt) / 1000 / 60

    if (elapsedMinutes < INTERVAL_MINUTES) {
      updates.push(folder.getName());
    }
  }

  if (_.isEmpty(updates)) {
    return;
  }

  message = updates.join(', ') + " was updated at https://drive.google.com/drive/u/0/folders/" + folderId + '\n' + message
  postMessage(message, channelName)
}

function main() {
  var sheet = SpreadsheetApp.getActive().getSheetByName('config');
  var rows = sheet.getDataRange().getValues();

  _.each(rows, function(row, i){
    if (i==0) return;  // skip header
    var folderId = row[0];
    var channelName = row[1];
    var message = row[2];
    checkFolder(folderId, channelName, message);
  });
}
```

# Slack新規チャンネル通知

チャンネルが乱立し始めた頃、新しくチャンネルが出来たら通知して欲しいとの要望から作成した。
予めconfigという空シートを作成しておくこと。

```
var CHANNEL_NAME = "lobby";
var SHEET_NAME = "config";
var ADDITIONAL_MESSAGE = "新しく作成されたチャンネルがあります。 "

function main() {
  var slackApp = SlackApp.create(TOKEN);
  var currentChannels = _.pluck(slackApp.channelsList().channels, 'name');
  var newChannels = [];

  var message = '';
  var sheet = SpreadsheetApp.getActive().getSheetByName(SHEET_NAME);
  var rows = _.map(sheet.getDataRange().getValues(), function(elm){ return elm.toString(); });

  _.each(currentChannels, function(channel, i) {
    if (!_.include(rows, channel)) {
      message += " #" + channel;
      newChannels.push(channel);
    }
  });

  _.each(newChannels, function(channel, i) {
    sheet.getRange('A' + (currentChannels.length - newChannels.length + i + 1)).setValue(channel);
  });

  if (message) postMessage(slackApp, ADDITIONAL_MESSAGE + message);

  _.each(currentChannels, function(channel, i) {
    sheet.getRange('A' + (i+1)).setValue(channel);
  });
}
```

# 環境センサ通知ボット

オフィスに人が増えてきて、場所によっては酸素が薄いみたいな話がチラホラ聞こえてきた。
なので、そのへんに転がってた（？）Netatmoをばら撒いて、二酸化炭素濃度が上がってきたら通知するようにした。

```
var CHANNEL_NAME = "lobby";
var THRESHOLD = 2000; // 通知しきい値
var STATION_NAME = "entrance";  // Netatmoにつけた名称

function getToken() {
  var url = 'https://api.netatmo.net/oauth2/token';
  var options = {
    'method': 'post',
    'payload': {
      'grant_type': 'password',  // パスワードフローでOAuthトークンを取得
      'username': 'hoge@fuga.com',
      'password' : 'XXXXXXX',
      'client_id': 'XXXXXXX',  // このへんの情報はNetatmoの設定ページから取得できる
      'client_secret': 'XXXXXXX'
     }
  };
  var json = UrlFetchApp.fetch(url, options).getContentText();
  var jsonData = JSON.parse(json);
  var token = jsonData["access_token"];
  return token;
}

function getCo2() {
  var url = "https://api.netatmo.com/api/getstationsdata";
  var options = {
    "headers" : {
      "Authorization" : "Bearer " + getToken()
    }
  };
  var json = UrlFetchApp.fetch(url, options);
  var jsonData = JSON.parse(json);
  var co2 = undefined
  jsonData["body"]["devices"].some(function(device, i) {
    if(device["station_name"] === STATION_NAME) {
      co2 = parseInt(device["dashboard_data"]["CO2"], 10); // Netatmoは二酸化炭素以外にも気温、湿度とか色々取れるはず
    }
  });
  if(!co2) {
    throw new Error("CO2が取得できませんでした");
  }
  return co2;
}

function main() {
  var co2 = getCo2();
  if(co2 > THRESHOLD) {
    postMessage(CHANNEL_NAME, "オフィスの二酸化炭素濃度:" + co2 + "が閾値:" + THRESHOLD + "を上回りました。換気をするか、呼吸を控えてください。");
  }
}
```

# Slack簡易対話ボット

自分用のチャンネルがあって、そこに訪問する人に対して、簡易的に応答するボットを用意している。

予め「responses」というシートに「発話内容」と「応答内容」の２列で色々と定義しておくこと。

```
var MAIN_CHANNEL_NAME = "my_room";
var SUB_CHANNEL_NAME = "bot_room";

function convertTime(unixtime) {
  var date = Moment.moment(new Date(unixtime*1000));
  return date.format("YYYY-MM-DD_HH:mm:ss");
}

function doPost(e) {
  if(e.parameter.userName === "slackbot") {
    return null; // 無限ループ防止
  }

  if (prop.verifyToken != e.parameter.token) {
    throw new Error("invalid token.");
  }

  if(e.parameter.channel_name === MAIN_CHANNEL_NAME) {
    var userName = e.parameter.user_name;
    sheet = SpreadsheetApp.getActive().getSheetByName(userName);

    if(!sheet) {
      sheet = SpreadsheetApp.getActive().insertSheet(userName);

      // 初めて投稿してくれた人へのメッセージ
      slackApp.chatPostMessage(e.parameter.channel_id, "ようこそ。" + e.parameter.user_name + "さん", {
        username : "bot",
        icon_emoji : ":penguin:"
      });
    }

    // 投稿内容に応じたレスポンスを返す
    response = findResponse(e.parameter.text);
    if(response) {
      slackApp.chatPostMessage(e.parameter.channel_id, response, {
        username : "bot",
        icon_emoji : ":penguin:"
      });
    } else {
      // 特にレスポンス内容が見つからなければ、SUB_CHANNEL_NAMEに投稿するだけ
      postMessage(SUB_CHANNEL_NAME, e.parameter.text);
    }

    // 後々の応答例用意のためにも、訪問者の投稿は保存（問題なさそうなチャンネルかどうかは要注意）。
    //sheet.appendRow([convertTime(e.parameter.timestamp), e.parameter.text, response]);

  } else {
    // SUB_CHANNEL_NAMEに投稿した内容をMAIN_CHANNEL_NAMEに投稿。元の投稿者からはあたかもbotが応答したように見える（かも）
    postMessage(MAIN_CHANNEL_NAME, e.parameter.text);
  }

  return null;
}

function findResponse(utterance) {
  // "responses"シートに定義された対話例の中から、発言を含むものを探し、あれば応答する。なければundefinedで応答しない。
  var response = getResponses().reduce(function(cache, row) { return cache || ((utterance.indexOf(row.utterance) != -1) && row.response); }, false) || undefined;
  return response;
}

function getResponses() {
  var sheet = SpreadsheetApp.getActive().getSheetByName("responses");
  var data = sheet.getDataRange().getValues();
  return data.map(function(row) { return {utterance: row[0], response: row[1]}; }); // １列目が発話内容、２列目が応答内容
}
```

# Googleカレンダー予定簡易確認ボット

協力会社の方など、社員用カレンダーを見れないが、（カレンダーで管理されている）会議室の予約をしたいという要望があった。
そのため、Slack上のスラッシュコマンドで空きの確認及び予約の作成を出来るようにした。

使い方
```
1. 予約済み時間の確認
/room small list 2019/03/17

2. 予約の登録
/room small create 2019/03/17 09:00 09:30 Aさんと1on1

小会議室：small
大会議室：large
```

https://api.slack.com/apps  にて、Create New Appすることにより、スラッシュコマンドで呼び出すBotを作る。
Botから呼び出し、カレンダーの管理をするGASは以下のとおり。

```
function doPost(e) {
  if (prop.verifyToken != e.parameter.token) {
    throw new Error("invalid token.");
  }

  var commands = e.parameter.text.split(" ");
  var roomType = commands[0];
  var command = commands[1];
  var targetDate = commands[2];

  if(roomType == "large") {
    var cal = CalendarApp.getCalendarById("大会議室のカレンダーID (Googleカレンダーの詳細ページに記載されているはず)");
  } else if(roomType == "small") {
    var cal = CalendarApp.getCalendarById("小会議室のカレンダーID");
  }

  if(command == "list") {
    // 予約の確認
    var text = '[予約済み]\n';
    var date = new Date(targetDate);　
    var events = cal.getEventsForDay(date);
    for each (var event in events) {
      var start = event.getStartTime();
      var end = event.getEndTime();
      text += "開始時刻: " + start.getHours() + ":" + start.getMinutes() + " 終了時刻: " + end.getHours() + ":" + end.getMinutes() + '\n';
    }
  } else if (command == "create") {
    // 予約の作成
    var text = '予約を作成しました';
    var targetStart = commands[3];
    var targetEnd = commands[4];
    var eventName = commands[5];
    var start = new Date(targetDate + " " + targetStart);　
    var end = new Date(targetDate + " " + targetEnd);　
    cal.createEvent(eventName, start, end, {description: 'Created By Bot'});
  }

  var res = {response_type: "in_channel", text: text};
  return ContentService.createTextOutput(JSON.stringify(res)).setMimeType(ContentService.MimeType.JSON);
}
```

# チャンネル常時翻訳

英語常用の社員も増えてきたし、言語由来の壁が出来ないように、雑談用のチャンネルは常時機械翻訳するようにした。
翻訳精度はまだ怪しいが、雰囲気の共有くらいは出来る（はず）。

```
var JA_CHANNEL_NAME = "lobby_ja";
var TRANS_JA_CHANNEL_NAME = "lobby_ja_trans";

var EN_CHANNEL_NAME = "lobby_en";
var TRANS_EN_CHANNEL_NAME = "lobby_en_trans";

function doPost(e) {
  if(e.parameter.user_name === "slackbot") {
    return null; // 無限ループ防止
  }

  if(e.parameter.channel_name === JA_CHANNEL_NAME) {
    var translation = LanguageApp.translate(e.parameter.text, 'ja', 'en');
    postMessage(TRANS_JA_CHANNEL_NAME, e.parameter.user_name, translation);

  } else if(e.parameter.channel_name === EN_CHANNEL_NAME) {
    var translation = LanguageApp.translate(e.parameter.text, 'en', 'ja');
    postMessage(TRANS_EN_CHANNEL_NAME, e.parameter.user_name, translation);
  }

  return null;
}
```
