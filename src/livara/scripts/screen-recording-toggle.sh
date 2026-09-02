#!/usr/bin/env bash
set -Eeuo pipefail

mode="${1:-audio}"
case "$mode" in
  audio|silent) ;;
  *)
    printf 'usage: %s [audio|silent]\n' "$0" >&2
    exit 2
    ;;
esac

output_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/livara/screen-recorder"
pid_file="$state_dir/recording.pid"
output_file="$state_dir/recording.output"
mode_file="$state_dir/recording.mode"
log_file="$state_dir/gpu-screen-recorder.log"
mkdir -p "$output_dir" "$state_dir"
umask 077

log_event() {
  printf '%s mode=%s pid=%s %s\n' "$(date --iso-8601=seconds)" "$mode" "${current_pid:-none}" "$*" >> "$log_file"
}

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -a "Livara" "Screen recording" "$1"
}

exec 9>"$state_dir/toggle.lock"
if ! flock -w 5 9; then
  notify "Recorder is busy; please try again."
  exit 1
fi

clear_state() {
  rm -f "$pid_file" "$output_file" "$mode_file"
}

process_alive() {
  local pid="$1" state command
  kill -0 "$pid" 2>/dev/null || return 1
  state="$(ps -p "$pid" -o stat= 2>/dev/null | tr -d ' ')"
  [[ -n "$state" && "$state" != Z* ]] || return 1
  command="$(ps -p "$pid" -o args= 2>/dev/null)"
  [[ "$command" =~ (^|/)gpu-screen-recorder([[:space:]]|$) ]]
}

current_pid=""
if [[ -s "$pid_file" ]]; then
  current_pid="$(<"$pid_file")"
  if ! process_alive "$current_pid"; then
    clear_state
    current_pid=""
  fi
fi

if [[ -n "$current_pid" ]]; then
  output="$(cat "$output_file" 2>/dev/null || true)"
  if [[ -z "$output" ]]; then
    notify "Recording state is incomplete; see $log_file"
    clear_state
    exit 1
  fi

  log_event "stop-request output=$output"
  kill -INT "$current_pid" 2>/dev/null || true
  for _ in {1..100}; do
    process_alive "$current_pid" || break
    sleep 0.1
  done
  if process_alive "$current_pid"; then
    kill -INT "$current_pid" 2>/dev/null || true
    for _ in {1..50}; do
      process_alive "$current_pid" || break
      sleep 0.1
    done
  fi

  if process_alive "$current_pid"; then
    notify "Could not stop the recording; see $log_file"
    exit 1
  fi

  # SIGINT requests a clean flush; wait for the output to become nonempty
  # before removing state, so the user gets an honest result notification.
  for _ in {1..30}; do
    [[ -s "$output" ]] && break
    sleep 0.1
  done
  clear_state
  if [[ -s "$output" ]]; then
    log_event "stop-complete output=$output bytes=$(stat -c %s "$output")"
    notify "Recording stopped and saved: $output"
  else
    log_event "stop-failed output=$output"
    notify "Recording stopped, but no video was saved; see $log_file"
    exit 1
  fi
  exit 0
fi

# Do not start a second recorder if the Noctalia plugin or another tool owns
# an active process that is not represented by our state file.
mapfile -t other_pids < <(pgrep -f '(^|/)gpu-screen-recorder([[:space:]]|$)' || true)
if ((${#other_pids[@]} > 0)); then
  notify "Another screen recorder is already running; no new recording started."
  exit 1
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
filename="screen_recording_${mode}_${timestamp}.mp4"
output="$output_dir/$filename"
sequence=1
while [[ -e "$output" ]]; do
  filename="screen_recording_${mode}_${timestamp}_${sequence}.mp4"
  output="$output_dir/$filename"
  sequence=$((sequence + 1))
done
printf '%s\n' "$output" > "$output_file"
printf '%s\n' "$mode" > "$mode_file"

record_args=(
  -w screen
  -f 60
  -k h264
  -fallback-cpu-encoding yes
  -cursor yes
  -v no
  -o "$output"
)
if [[ "$mode" == audio ]]; then
  record_args+=( -a default_output -ac opus )
fi
log_event "start-request output=$output args=${record_args[*]}"

gpu-screen-recorder "${record_args[@]}" >>"$log_file" 2>&1 9>&- &
printf '%s\n' "$!" > "$pid_file"
current_pid="$!"
log_event "start-fork output=$output args=${record_args[*]}"

# A successful fork is not enough: ensure GSR survived initialization.
for _ in {1..20}; do
  pid="$(<"$pid_file")"
  if process_alive "$pid"; then
    exit 0
  fi
  sleep 0.1
done

log_event "start-failed output=$output"
clear_state
rm -f "$output"
notify "Screen recording could not start; see $log_file"
exit 1
