#!/usr/bin/env bash

TMP_OUTPUT="./tmp.out";

COLOR_OFF="\e[0m";
DIM="\e[2m";
RED="\e[31m";
GREEN="\e[32m";

function redraw_and_run {
  clear;

  echo -en "${DIM}";
  date -R;
  echo -en "${COLOR_OFF}";

  run;
}

function run {

  ALL_TESTS_PASSED=true;

  for INPUT in tests/*.in; do
    racket src/elmlisp.rkt ${INPUT} >${TMP_OUTPUT};
    TEST_NAME=$(basename ${INPUT} .in);
    WANTED_OUTPUT="tests/${TEST_NAME}.out";
    if ! colordiff -B ${TMP_OUTPUT} ${WANTED_OUTPUT}; then
      echo -e "${RED}Test failed: ${TEST_NAME}${COLOR_OFF}"
      ALL_TESTS_PASSED=false;
    fi;
  done;
  
  rm -f tmp.out;
  
  if [ "${ALL_TESTS_PASSED}" = true ]; then
    echo -e "${GREEN}All tests passed!${COLOR_OFF}"
  fi;

}

redraw_and_run;

while inotifywait -qqre modify ./tests ./src; do
  redraw_and_run;
done;

