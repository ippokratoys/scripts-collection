#!/bin/bash

# If variable set to 0 then the commands will not be executed
# If variable set to 1 then the code will be executed
DRY_RUN=0

function run_command() {
  if [ "$DRY_RUN" == "0" ]; then
    echo $@
  else
    $@
  fi
}

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

GIT_ROOT_PROJECT='/home/thanasis/Documents/Blueground/atlas'
BRANCH_NAME=$1
PROTECTED_BRANCHES=('develop' 'master')
echo "Will rebase with develop and push the following branch:$BRANCH_NAME"

# Wrong usage
if [ $# -ne 1 ]; then
  echo "Usage : $0 chore/bb-420"
  echo "Where chore/bb-420 can be any branch expect master/develop"
  exit
fi

# Move to git project
cd $GIT_ROOT_PROJECT

# Check if given branch exists
COUNT_BRANCH_WIHT_NAME=$(git branch | tr -d ' ' | grep --line-regexp $BRANCH_NAME | wc -l)
if [ $COUNT_BRANCH_WIHT_NAME -eq 0 ]; then
  echo "Branch with name $BRANCH_NAME not found"
  exit 1
fi

# Check if given branch is dangerous
A=$PROTECTED_BRANCHES
if [ $(contains "${A[@]}" "${BRANCH_NAME}") == "y" ]; then
  echo "Branch with name $BRANCH_NAME is dangerous. Do it by yourself <3"
  exit 2
fi

# Get the name of the current branch
INITIAL_BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
echo "You are currently on branch:$INITIAL_BRANCH_NAME"

# Count file taht changed and keek a boolean indicating any file has changed
CHANGED_FILES=$(git status --porcelain|wc -l)
if [ $CHANGED_FILES -eq 0 ]; then
  echo 'No untracked files'
  HAS_CHANGES=0
else
  echo 'Some untracked files.'
  HAS_CHANGES=1
fi

if [ "$HAS_CHANGES" -eq "1" ]; then
  echo 'Stashing untracked files...'
  run_command git stash
fi

# Fetch any changes from remote
run_command git fetch --quiet

run_command git checkout $BRANCH_NAME
run_command git pull
run_command git rebase --interactive --autosquash origin/develop
run_command git push --force-with-lease
run_command git checkout $INITIAL_BRANCH_NAME

if [ "$HAS_CHANGES" -eq "1" ]; then
  run_command 'git stash pop'
fi
