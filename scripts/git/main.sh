#!/bin/bash
set -euo pipefail 
source "$(dirname ${BASH_SOURCE[0]})"/../utils/display.sh

if [ ! -d ".git" ]; then 
    cd "$(dirname ${BASH_SOURCE[0]})/../../"
    git init
    git add .
    git commit -m "feat/first-commit"
    git remote add origin git@github.com:flavlmne/Terraform.git 
    git remote -v
else 
    display_msg "⚠️ Already a git repo" warning  # $1="Already a git repo" $2=info
fi

