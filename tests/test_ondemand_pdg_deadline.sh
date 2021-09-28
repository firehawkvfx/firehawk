#!/bin/bash

# This is an automated cook test.

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # The directory of this script
mount_cloud_prod="/Volumes/cloud_prod"
test_dir="$mount_cloud_prod/tests"
output_dir="$test_dir/geo"
output_file="$output_dir/test_ondemand_pdg_deadline.spheregeo.0001.bgeo.sc"

function print_usage {
  echo
  echo "Usage: ./test_ondemand_pdg_deadline.sh [OPTIONS]"
  echo
  echo "Tests a PDG task using a cloud ondemand instance."
  echo
  echo "Options:"
  echo
  echo -e "  --fail\tEnforce a test failure."
  echo -e "  --pass\tEnforce a test pass."
  echo -e "  --help\tShow args / options."
  echo
  echo "Example: Run the test and log times."
  echo
  echo "  time ./test_ondemand_pdg_deadline.sh | ts"
}

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

function log_warn {
  local -r message="$1"
  log "WARN" "$message"
}

function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

function cleanup {
  verbose=$1

  if [[ "$verbose" == "true" ]]; then
    echo ""
    echo "...Cleaning up."
    sudo rm -frv $test_dir
    echo "...Cleanup done."
  else
    sudo rm -fr $test_dir
  fi

}

function init {
  echo "...Ensuring filegateway is mounted"
  mount | grep $mount_cloud_prod

  cleanup "true"

  echo ""
  mkdir "$test_dir"
  mkdir "$output_dir"
  sudo chown -R 9001:9001 "$test_dir"
  sudo chmod -R 777 "$test_dir"

  echo "Copy test files..."
  cp -frv $SCRIPTDIR/test_ondemand_pdg_deadline* "$test_dir"

  echo ""
  cd /opt/hfs18.5; source ./houdini_setup
  cd $SCRIPTDIR
}

function run_procedure {
    echo "...Run procedure"
    hython $test_dir/test_ondemand_pdg_deadline.hip $test_dir/test_ondemand_pdg_deadline.py
}

function enforce_pass {
    echo "Enforcing test pass"
    touch $output_file
}

function enforce_fail {
    echo "Enforcing test failure"
}

function test_result {
    echo ""
    echo "Test Result:"
    sleep 1
    if [[ ! -f "$output_file" ]]; then
        echo "FAILED: output was not on disk after test at path: $output_file"
        cleanup "false"
        exit 1
    else
        echo "PASSED: output was found on disk after test at path: $output_file"
        cleanup "false"
        exit 0
    fi
}


function run_test {
  local mode="default"
  
  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --fail)
        mode="fail"
        shift
        ;;
      --pass)
        mode="pass"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        log_error "Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac

    shift
  done

  init

  if [[ "$mode" == "default" ]]; then
      run_procedure
  elif [[ "$mode" == "pass" ]]; then
      enforce_pass
  elif [[ "$mode" == "fail" ]]; then
      enforce_fail
  fi

  test_result

}

run_test "$@"