# Subsystem fan-out helpers mirroring .global/make/subsystem.mk behavior.

SUBSYSTEM_SETUP := '''
subsystem_name="${SUBSYSTEM_NAME:-$(basename "$PWD")}"
subsystem_stacks_raw="${SUBSYSTEM_STACKS:-}"

trim() { printf '%s' "$1" | xargs; }
normalize() { printf '%s' "$1" | tr '-.' '__'; }

subsystem_stacks="$(trim "$subsystem_stacks_raw")"
if [ -z "$subsystem_stacks" ]; then
  echo "SUBSYSTEM_STACKS must be defined before using subsystem helpers." >&2
  exit 1
fi

subsystem_default_actions="$(trim "${SUBSYSTEM_DEFAULT_ACTIONS:-}")"

stack_actions() {
  local stack="$1"
  local var="STACK_ACTIONS_$(normalize "$stack")"
  local value="${!var:-}"
  value="$(trim "$value")"
  if [ -z "$value" ]; then
    value="$subsystem_default_actions"
  fi
  printf '%s\n' "$value"
}

action_in_list() {
  local action="$1"
  local list="$2"
  for item in $list; do
    if [ "$item" = "$action" ]; then
      return 0
    fi
  done
  return 1
}

subsystem_action_message() {
  local action="$1"
  local var="SUBSYSTEM_ACTION_MESSAGE_$(normalize "$action")"
  local value="${!var:-}"
  printf '%s' "$value"
}

run_action() {
  local action="$1"
  local handled=0
  for stack in $subsystem_stacks; do
    local actions
    actions="$(stack_actions "$stack")"
    if action_in_list "$action" "$actions"; then
      handled=1
      echo "==> $stack: $action"
      (cd "$stack" && just "$action") || return $?
    fi
  done
  if [ $handled -eq 0 ]; then
    local msg
    msg="$(subsystem_action_message "$action")"
    if [ -n "$msg" ]; then
      echo "$msg"
    else
      echo "$subsystem_name: no stacks configured for $action."
    fi
  fi
}
'''

sync:
	echo "==> Running subsystem sync"
	{{SUBSYSTEM_SETUP}}
	run_action sync

bootstrap:
	echo "==> Running subsystem bootstrap"
	{{SUBSYSTEM_SETUP}}
	run_action bootstrap

wait:
	echo "==> Running subsystem wait"
	{{SUBSYSTEM_SETUP}}
	run_action wait

clean:
	echo "==> Running subsystem clean"
	{{SUBSYSTEM_SETUP}}
	run_action clean

fan-out:
	echo "==> Running subsystem action"
	{{SUBSYSTEM_SETUP}}
	action="${ACTION:-}"
	[ -n "$action" ] || { echo "ACTION not set; export ACTION=<action> to use subsystem::fan-out."; exit 1; }
	run_action "$action"
