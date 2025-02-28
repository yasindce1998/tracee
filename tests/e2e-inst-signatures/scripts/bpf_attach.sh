#!/bin/bash

TRACEE_STARTUP_TIMEOUT=60
TRACEE_SHUTDOWN_TIMEOUT=60
TRACEE_RUN_TIMEOUT=5

TRACEE_TMP_DIR=/tmp/tracee

info_exit() {
    echo -n "INFO: "
    echo "$@"
    exit 0
}

info() {
    echo -n "INFO: "
    echo "$@"
}

# run tracee with a single event (to trigger the other instance)

coproc ./dist/tracee \
    --install-path $TRACEE_TMP_DIR \
    --events security_file_open &

pid=$COPROC_PID

# wait tracee to be started + 5 seconds

times=0
timedout=0

while true; do
    times=$((times + 1))
    sleep 1

    if [[ -f $TRACEE_TMP_DIR/out/tracee.pid ]]; then
        info "bpf_attach test tracee instance started"
        break
    fi

    if [[ $times -gt $TRACEE_STARTUP_TIMEOUT ]]; then
        timedout=1
        break
    fi
done

if [[ $timedout -eq 1 ]]; then
    info_exit "could not start the bpf_attach test tracee instance"
fi

sleep $TRACEE_RUN_TIMEOUT # stay alive for sometime (proforma)

# try a clean exit
kill -2 "$pid"

# wait tracee to shutdown (might take sometime, detaching is slow >= v6.x)
sleep $TRACEE_SHUTDOWN_TIMEOUT

# make sure tracee is exited with SIGKILL
kill -9 "$pid" >/dev/null 2>&1

exit 0
