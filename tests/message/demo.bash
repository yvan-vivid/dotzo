# shellcheck shell=bash
# Demo for messages

declare here
here="$(dirname "$0")"

# Loading testing lib
# shellcheck source=../../lib/message.bash
source "$here/../../lib/message.bash"

section() {
  echo "============================================================"
  echo "== $1" 
  echo "============================================================"
}

log_demo_messages() {
  log_debug "This is a debug message."
  log_info  "This is a info message."
  log_warn  "This is a warn message."
  log_error "This is a error message."
}

logging_demo() {
  section "Logging demo"
  set_color_mode

  for level in "silent" "error" "warn" "info" "debug"; do
    echo "Logging with level = $level"
    echo "<start>"
    set_log_level "$level"
    log_demo_messages
    echo "<end>"
    echo ""
  done
 
  echo "Logging without markup for log files."
  echo "<start>"
  set_log_mode
  log_demo_messages
  echo "<end>"
  
  echo ""
}

messaging_demo() {
  set_color_mode
  section "Messaging demo"
  message_checked "This is a checked message."
  message_exed    "This is an exed message."
  message_notify  "This is a notification message."
  echo ""
}

prompting_demo() {
  set_color_mode
  section "Prompting demo"
  echo ""
  echo "Prompt affirmative with 'y':"
  echo "y" | prompt_confirm "This is a prompt."
  echo ""
  echo "Prompt negative with 'n':"
  echo "n" | prompt_confirm "This is a prompt."
  echo ""
}

logging_demo
messaging_demo
prompting_demo

echo ""
echo "Finished"
echo ""
