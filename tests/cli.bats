#!/usr/env bats
# vim: ft=sh

load test_helper/bats-support/load
load test_helper/bats-assert/load

load "../lib/cli"


cli_output() {
  local -r out="$1" entry="$BATS_TEST_DIRNAME/test_cli_1.bash"; shift
  run bash "$entry" "$@"
  assert_output "$out"
}

cli_fail() {
  local -r entry="$BATS_TEST_DIRNAME/test_cli_1.bash"
  run bash "$entry" "$@"
  assert_failure
}

@test "short parameters" {
  cli_output "1::::"   -a
  cli_output "1::1::"  -ac
  cli_output "1::1::"  -ca
  cli_output "1::1::"  -c -a
  cli_output "1:x:::"  -ab x
  cli_output "1:x:1::" -acb x
}

@test "long parameters" {
  cli_output "1:x:1:w:" -acb x --long-name w
}

@test "long and short parameters" {
  cli_output "1::1::" --coffee -a
  cli_output "1:x:::" --banana x -a
}

@test "positional parameters" {
  cli_output "::::n m k j" n m k j
  cli_output "1:x:1:w:n m k j" n -acb x m k --long-name w j
  cli_output "1:x:1:w:n m k j" n -acb x m k --long-name=w j
  cli_output "1::1:w=a--b-c:j" -ac --long-name=w=a--b-c j
}

@test "missing params" {
  cli_fail x y z --long-name
  cli_fail x y z --b
}

@test "unknown options" {
  cli_fail --non
  cli_fail -az
}

@test "incorrect explict parameters" {
  cli_fail --a=5
}
