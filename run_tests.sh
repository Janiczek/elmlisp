#!/usr/bin/env bash

ERRORS_FILE="errors.txt";

COLOR_OFF="\e[0m";
RED="\e[31m";
DIM="\e[2m";

function compile {
  raco exe test_runner.rkt &>${ERRORS_FILE};
}

function recompile {
  echo "Sources changed, recompiling!";
  compile;
}

function redraw_and_run {
  clear;

  echo -en "${DIM}";
  date -R;
  echo -en "${COLOR_OFF}";

  ./test_runner;
}

function show_compiler_errors {
  echo -e "${RED}\nErrors:\n${COLOR_OFF}$(cat ${ERRORS_FILE})\n";
}

compile;

if [[ -z $(cat ${ERRORS_FILE}) ]]; then
  redraw_and_run;
else
  show_compiler_errors;
fi;

rm -f ${ERRORS_FILE};

inotifywait -mqr -e close_write,move,create,delete --format '%w %e %f' ./tests ./src ./examples ./test_runner.rkt @compiled | while read DIR EVENT FILE; do

  #echo "event: ${EVENT} // dir: ${DIR} // file: ${FILE}" >>events.txt # debugging

  if [ "${FILE}" != "elmlisp" ] && [ "${DIR}" == "./src/" ] || [ "${DIR}" == "./test_runner.rkt" ]; then
    recompile;
  fi;

  if [[ -z $(cat ${ERRORS_FILE}) ]]; then
    redraw_and_run;
  else
    echo -e "${RED}\nErrors:\n${COLOR_OFF}$(cat ${ERRORS_FILE})\n";
  fi;

  rm -f ${ERRORS_FILE};

done;

