#!/bin/sh

open http://127.0.0.1:1313/blog/ && hugo server --watch --buildDrafts
