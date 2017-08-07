#!/usr/bin/env bash

TMP_OUTPUT="./tmp.out";
TEST_INPUTS="tests/*.in";

COLOR_OFF="\e[0m";
DIM="\e[2m";
RED="\e[31m";
GREEN="\e[32m";
HOME="\e[2K\e[200D";

function redraw_and_run {
  clear;

  echo -en "${DIM}";
  date -R;
  echo -en "${COLOR_OFF}";

  run;
}

function run {

  NUMBER_OF_TESTS=$(ls ${TEST_INPUTS} | wc -l);
  ALL_TESTS_PASSED=true;
  CURRENT_TEST=0;

  for INPUT in ${TEST_INPUTS}; do
    ((CURRENT_TEST++))
    TEST_NAME=$(basename ${INPUT} .in);
    echo -en "${HOME}${CURRENT_TEST}/${NUMBER_OF_TESTS}: ${TEST_NAME}";
    racket src/elmlisp.rkt ${INPUT} >${TMP_OUTPUT};
    WANTED_OUTPUT="tests/${TEST_NAME}.out";
    if ! colordiff -B ${TMP_OUTPUT} ${WANTED_OUTPUT}; then
      ALL_TESTS_PASSED=false;
      break;
    fi;
  done;
  
  rm -f tmp.out;
  echo -en "${HOME}"
  
  if [ "${ALL_TESTS_PASSED}" = true ]; then
    echo -e "${GREEN}All tests passed!${COLOR_OFF}";
  else
    echo -e "${RED}Test failed: ${TEST_NAME}${COLOR_OFF}";
  fi;
}

redraw_and_run;

while inotifywait -qqre modify ./tests ./src; do
  redraw_and_run;
done;

