#!/usr/bin/env bash
set -u

LOG_DIR="${LOG_DIR:-/work/logs}"
STDOUT_LOG="${STDOUT_LOG:-${LOG_DIR}/stdout.log}"
STDERR_LOG="${STDERR_LOG:-${LOG_DIR}/stderr.log}"

mkdir -p "${LOG_DIR}"
touch "${STDOUT_LOG}" "${STDERR_LOG}"

exec > >(tee -a "${STDOUT_LOG}" /proc/1/fd/1) 2> >(tee -a "${STDERR_LOG}" /proc/1/fd/2 >&2)

status=0

echo "=== tester stage: ssort Python formatting check ==="
if ! ssort --check /work/app /work/tests; then
    status=1
fi

echo "=== tester stage: pylint static analysis with 10 selected criteria ==="
if pylint --rcfile=/work/pylintrc /work/app/bad_code.py; then
    echo "pylint did not detect the expected violations"
    status=1
else
    echo "pylint detected the expected violations"
fi

echo "=== tester stage: requests integration test for HTTP headers ==="
for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if python3 /work/tests/integration/test_headers.py; then
        break
    fi

    if [ "${attempt}" = "10" ]; then
        status=1
        break
    fi

    echo "Application is not ready yet, retry ${attempt}/10"
    sleep 2
done

if [ "${status}" = "0" ]; then
    echo "=== tester result: all checks passed ==="
else
    echo "=== tester result: at least one check failed ==="
fi

exit "${status}"
