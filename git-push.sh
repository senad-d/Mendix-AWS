#!/bin/bash

git remote set-url origin <origin>
git push
wait
git remote set-url origin <mendix-origin>