http://blog.hassaku-labs.com/

# Write

```
$ hugo new post/XXXXX.md
$ vi post/XXXXX.md
$ hugo server -D -w    # showing draft and reloading automatically
```

# Publish

```
$ hugo undraft content/post/XXXXX.md
$ git branch
* master
$ git commit
$ git push origin master
$ hugo -d pages    # published into pages directory
```

# Deploy

```
$ cd pages
$ git branch
* gh-pages
$ git add XXXXXX
$ git commit -a
$ git push origin gh-pages
```

------

# Setup

```
$ hugo new site blog
$ cd blog
$ git init
$ mkdir themes
$ git clone https://github.com/tanksuzuki/angels-ladder themes/angels-ladder
$ vi config.toml

$ git remote add origin git@github.com:hassaku/blog.git
$ git add -A
$ git commit
$ git push -u origin master

$ git checkout -b gh-pages
$ rm -rf *
$ git rm -rf .
$ echo blog.hassaku-labs.com > CNAME
$ git commit -m "Init GitHub Pages branch."
$ git push origin gh-pages

$ git checkout master
$ git clone -b gh-pages git@github.com:hassaku/blog.git pages
```

