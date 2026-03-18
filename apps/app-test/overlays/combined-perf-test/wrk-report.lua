-- wrk-report.lua
-- Lua script for wrk that writes a JSON summary to /results/wrk-result.json
-- and also emits it to stdout (captured in pod logs).
-- Called automatically by wrk when the test finishes.

function done(summary, latency, requests)
  local duration_s = summary.duration / 1e6   -- microseconds → seconds
  local rps        = summary.requests / duration_s
  local bps        = summary.bytes    / duration_s

  local result = string.format(
    '{\n'                                                          ..
    '  "tool":             "wrk",\n'                              ..
    '  "duration_s":       %.3f,\n'                               ..
    '  "requests_total":   %d,\n'                                 ..
    '  "bytes_total":      %d,\n'                                 ..
    '  "requests_per_sec": %.2f,\n'                               ..
    '  "bytes_per_sec":    %.2f,\n'                               ..
    '  "latency_ms": {\n'                                         ..
    '    "min":   %.3f,\n'                                        ..
    '    "max":   %.3f,\n'                                        ..
    '    "mean":  %.3f,\n'                                        ..
    '    "stdev": %.3f,\n'                                        ..
    '    "p50":   %.3f,\n'                                        ..
    '    "p75":   %.3f,\n'                                        ..
    '    "p90":   %.3f,\n'                                        ..
    '    "p95":   %.3f,\n'                                        ..
    '    "p99":   %.3f\n'                                         ..
    '  },\n'                                                      ..
    '  "errors": {\n'                                             ..
    '    "connect": %d,\n'                                        ..
    '    "read":    %d,\n'                                        ..
    '    "write":   %d,\n'                                        ..
    '    "status":  %d,\n'                                        ..
    '    "timeout": %d\n'                                         ..
    '  }\n'                                                       ..
    '}\n',
    duration_s,
    summary.requests,
    summary.bytes,
    rps,
    bps,
    latency.min            / 1000,
    latency.max            / 1000,
    latency.mean           / 1000,
    latency.stdev          / 1000,
    latency:percentile(50) / 1000,
    latency:percentile(75) / 1000,
    latency:percentile(90) / 1000,
    latency:percentile(95) / 1000,
    latency:percentile(99) / 1000,
    summary.errors.connect,
    summary.errors.read,
    summary.errors.write,
    summary.errors.status,
    summary.errors.timeout
  )

  -- Persist to file so results survive past process exit
  local f = io.open("/results/wrk-result.json", "w")
  if f then
    f:write(result)
    f:close()
  end

  -- Also emit to stdout so kubectl logs captures it
  io.write(result)
end
