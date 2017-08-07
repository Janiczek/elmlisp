#!/usr/bin/env bash

COLOR_OFF="\e[0m";
DIM="\e[2m";

function compile {
  echo "Sources changed, recompiling!";
  raco exe test_runner.rkt;
}

function redraw_and_run {
  clear;

  echo -en "${DIM}";
  date -R;
  echo -en "${COLOR_OFF}";

  ./test_runner;
}

if [ ! -f test_runner ]; then
  compile;
fi;

redraw_and_run;

inotifywait -mqr -e close_write,move,create,delete --format '%w %e %f' ./tests ./src @compiled | while read DIR EVENT FILE; do

  # echo "${EVENT} ${DIR} ${FILE}" >>events.txt # debugging for why it recompiles twice in a row

  if [ "${DIR}" == "./src/" ]; then
    compile;
  fi;

  redraw_and_run;

done;

