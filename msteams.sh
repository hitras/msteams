#!/bin/bash -e

[ -z "$CURL" ] && CURL="$(which curl)"
[ -z "$MSTEAMS_PROXY" ] && MSTEAMS_PROXY="$HTTPS_PROXY"

usage() {
  cat <<EOS
USAGE
  msteams [JSON_PATTERN]
REQUIRED
  - curl  
DESCRIPTION
  Notify Microsoft Teams channel
ENVIRONMENTS
  MSTEAMS_URL     **required**. URL for Incoming Webhook of Microsoft Teams(e.g. https://outlook.office.com/webhook/xxxxxxx)
  MSTEAMS_PROXY   **OPTION**, Set http[s] proxy. set above $HTTPS_PROXY 
  HTTPS_PROXY     **OPTION**. Set http[s] proxy. set below $MSTEAMS_PROXY
OPTIONS:
  None
DETAILS
  **Warnings**
  If both of "named pipe" and "argment" is operated, "argument" is prior. A example is prior to "this is test2".
    echo "this is test1" | msteams "this is test2"

  1. named pipe
    echo "this is test" | msteams
  2. argument
    msteams "this is test"
EOS
}

cleanup() {
  return 0
}

echo_error() {
  echo "$@" >&2
}

prepare() {
  trap cleanup EXIT

  if ! parse_options "$@"; then
    usage
    exit 1
  fi

  # named pipe
  if [ -z "$MSG" ]; then
    if [ -p /dev/stdin ]; then
      MSG=$(cat -)
    else
      usage
	  exit 1
    fi
  fi

  # required program installed check.
  if [ ! -x "$CURL" ]; then
    echo_error "Error: curl is not executable."
    exit 1
  fi
}

parse_options() {
  MSTEAMS_PROXY="-x $MSTEAMS_PROXY"

  while getopts p:h OPT; do
    case $OPT in
      p)
        MSTEAMS_PROXY="-x $OPTARG"
        ;;
      *)
        return 1
        ;;
    esac  
  done
  shift $((OPTIND - 1))

  MSG="$1"
  return 0
}

check_params() {
  [ -z "$MSG" ] && echo_error "Error: Message is Empty." && exit 1
  [ -z "$MSTEAMS_URL" ] && echo_error "Error: Env MSTEAMS_URL is Empty." && exit 1
  return 0
}

post() {
  RES=$("$CURL" -s "$PROXY" -H 'Content-Type: application/json' -d "$MSG" -o /dev/null -w '%{http_code}\n' $MSTEAMS_URL | tail -n1)
  if [ "$RES" != "1200" ]; then
    echo_error "Error: Microsoft Teams webhook Post Error(http status code: $RES)"
    exit 1
  fi
  return 0
}

main() {
  prepare "$@"
  check_params
  post
  exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi

exit 1