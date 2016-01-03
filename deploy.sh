#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Commit master
msg="Update site `LC_ALL=en date`"
git add -A
git commit -m "$msg"
git push origin master

# Build the project.
hugo -d pages

cd pages
git add -A
msg="Rebuild site `LC_ALL=en date`"
git commit -m "$msg"

git push origin gh-pages 
cd ..
