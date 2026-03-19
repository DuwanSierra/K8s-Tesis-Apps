#!/bin/sh
set -euo pipefail

SERVER_HOST="${SERVER_HOST:-iperf3-server.iperf-test.svc.cluster.local}"
TCP_RUNS="${TCP_RUNS:-3}"
TCP_DURATION="${TCP_DURATION:-30}"
TCP_PARALLEL="${TCP_PARALLEL:-4}"
TCP_OMIT="${TCP_OMIT:-5}"
UDP_RUNS="${UDP_RUNS:-3}"
UDP_DURATION="${UDP_DURATION:-30}"
UDP_BANDWIDTH="${UDP_BANDWIDTH:-500M}"
UDP_PACKET_SIZE="${UDP_PACKET_SIZE:-1200}"
RESULT_DIR="${RESULT_DIR:-/results}"

log() {
  printf '[%s] %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$*"
}

run_tcp_suite() {
  MODE="$1"
  EXTRA_ARGS=""
  case "$MODE" in
    forward)
      EXTRA_ARGS=""
      ;;
    reverse)
      EXTRA_ARGS="-R"
      ;;
    *)
      log "unknown TCP mode $MODE"
      return 1
      ;;
  esac

  run=1
  while [ "$run" -le "$TCP_RUNS" ]; do
    FILE="$RESULT_DIR/tcp-${MODE}-run-${run}.json"
    log "TCP ${MODE} run ${run}/${TCP_RUNS}"
    iperf3 -c "$SERVER_HOST" -t "$TCP_DURATION" -O "$TCP_OMIT" -P "$TCP_PARALLEL" -f m $EXTRA_ARGS -J \
      | tee "$FILE"
    run=$((run + 1))
  done
}

run_udp_suite() {
  run=1
  while [ "$run" -le "$UDP_RUNS" ]; do
    FILE="$RESULT_DIR/udp-run-${run}.json"
    log "UDP run ${run}/${UDP_RUNS}"
    iperf3 -c "$SERVER_HOST" -u -b "$UDP_BANDWIDTH" -l "$UDP_PACKET_SIZE" -t "$UDP_DURATION" -f m -J \
      | tee "$FILE"
    run=$((run + 1))
  done
}

mkdir -p "$RESULT_DIR"
log "Starting iperf3 performance test against $SERVER_HOST"
log "TCP duration=${TCP_DURATION}s parallel=${TCP_PARALLEL} runs=${TCP_RUNS}"
log "UDP duration=${UDP_DURATION}s bandwidth=${UDP_BANDWIDTH} runs=${UDP_RUNS}"

run_tcp_suite forward
run_tcp_suite reverse
run_udp_suite

log "All test suites completed. Files stored under $RESULT_DIR"
