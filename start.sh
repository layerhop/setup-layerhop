#!/usr/bin/env bash
# Starts `layerhop dev` in the background, waits for /v1/health and exports LAYERHOP_API_URL.
# The mock API runs until the job ends. It never touches a real chain: its transactions are placeholders.
set -euo pipefail

port="${LH_PORT:-8787}"
log="${RUNNER_TEMP:-/tmp}/layerhop-dev.log"
args=(dev --port "$port" --fill-after "${LH_FILL_AFTER:-1}")

secret=""
if [[ -n "${LH_WEBHOOK_URL:-}" ]]; then
  secret="${LH_WEBHOOK_SECRET:-}"
  if [[ -z "$secret" ]]; then
    secret="whsec_$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
  fi
  echo "::add-mask::$secret"
  args+=(--webhook-url "$LH_WEBHOOK_URL" --secret "$secret")
fi
if [[ "${LH_FORK:-false}" == "true" ]]; then
  args+=(--fork --fork-chains "${LH_FORK_CHAINS:-base,arbitrum}")
fi

if [[ -n "${LH_CLI:-}" ]]; then
  # shellcheck disable=SC2206 # intentional word splitting of a command like "node path/to/index.js"
  cmd=(${LH_CLI})
else
  cmd=(npx --yes "@layerhop/cli@${LH_CLI_VERSION:-latest}")
fi

echo "Starting: ${cmd[*]} dev --port $port ..."
nohup "${cmd[@]}" "${args[@]}" >"$log" 2>&1 &
echo $! >"${RUNNER_TEMP:-/tmp}/layerhop-dev.pid"

url="http://127.0.0.1:${port}"
deadline=$((SECONDS + ${LH_TIMEOUT:-60}))
until curl -fsS "$url/v1/health" >/dev/null 2>&1; do
  if ((SECONDS >= deadline)); then
    echo "::error::The LayerHop mock API did not start within ${LH_TIMEOUT:-60}s"
    cat "$log" || true
    exit 1
  fi
  sleep 1
done

echo "LAYERHOP_API_URL=$url" >>"$GITHUB_ENV"
echo "api-url=$url" >>"$GITHUB_OUTPUT"
if [[ -n "$secret" ]]; then
  echo "LAYERHOP_WEBHOOK_SECRET=$secret" >>"$GITHUB_ENV"
  echo "webhook-secret=$secret" >>"$GITHUB_OUTPUT"
fi
echo "LayerHop mock API is up on $url (log: $log)"
