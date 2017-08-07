#!/usr/bin/env bash

TMP_OUTPUT="tmp.out";

ALL_TESTS_PASSED=true

for INPUT in tests/*.in; do
  racket src/elmlisp.rkt ${INPUT} >${TMP_OUTPUT};
  TEST_NAME=$(basename ${INPUT} .in);
  WANTED_OUTPUT="tests/${TEST_NAME}.out";
  if ! diff -B ${TMP_OUTPUT} ${WANTED_OUTPUT} &>/dev/null; then
    echo "Test failed: ${TEST_NAME}"
    ALL_TESTS_PASSED=false
  fi;
done;

rm -f tmp.out;

if [ "${ALL_TESTS_PASSED}" = true ]; then
  echo "All tests passed!"
fi;
