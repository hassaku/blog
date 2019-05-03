+++
date = "2018-08-10T10:00:00+09:00"
description = ""
draft = false
tags = ["python", "AI"]
title = "ターミナル上でシンプルなグリッドワールド"
+++

強化学習などでグリッドワールドを使いたいとき、gym-minigridとかpycolabがあるけど、色々いじる必要性もある場合、もっとシンプルなところからはじめたい。
また、リモートのVMインスタンス上などで気軽に動かしたいので、GUIとかも無しで、ターミナル上で動かしたい。

以下のような感じで、cursesを使ってスクラッチで作っても別に難しいことはなかった。

こんな感じのやつがターミナル上で動く。

![grid-world](/images/post/grid-world.gif)

```
import curses
import random
import time
from datetime import datetime

FIELD = ['#################',
         '#       #       #',
         '#       #       #',
         '#       #       #',
         '#               #',
         '#       #       #',
         '######  #########',
         '#       #       #',
         '#       #       #',
         '#               #',
         '#       #       #',
         '#       #       #',
         '#################']


def draw(screen):
    for row, line in enumerate(FIELD):
        for col, tile in enumerate(line):
            screen.addch(row, col, tile)


def main():
    x = 10
    y = 10

    try:
        screen = curses.initscr()
        screen.nodelay(1)
        curses.curs_set(0)

        while(True):
            action = random.randint(1, 5)
            dx = 0
            dy = 0
            if action == 1:
                dy += 1
            elif action == 2:
                dy -= 1
            elif action == 3:
                dx += 1
            elif action == 4:
                dx -= 1
            elif action == 5:
                pass
            else:
                raise NotImplementedError()

            # check wall
            if FIELD[x + dx][y + dy] != "#":
                x += dx
                y += dy

            screen.clear()
            draw(screen)
            screen.addch(x, y, '+') # agent

            screen.addstr(0, 20, datetime.now().strftime("%Y/%m/%d %H:%M:%S"))
            screen.addstr(1, 20, 'a:{} x:{} y:{}'.format(action, x, y))
            screen.refresh()

            # quit
            if(screen.getch() == ord('q')):
                break

            time.sleep(0.2)

        curses.endwin()

    except:
        pass

    finally:
        curses.echo()
        curses.endwin()


if __name__ == '__main__':
    main()
```

もしエージェントとインタラクションしたいと思ったら、flaskとかでapi作って状態変えるのが良いと思う。やり方はまた別の機会に。

