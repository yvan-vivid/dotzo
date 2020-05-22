#!/usr/env bats
# vim: ft=sh

load test_helper/bats-support/load
load test_helper/bats-assert/load

load "../lib/parser"

@test "parsing config" {
  local -r config="$BATS_TEST_DIRNAME/test_config"
  config_parser "prefix" < "$config"
  assert_equal "$prefix__first_section__key_one" "value"
  assert_equal "$prefix__first_section__key_two" "quoted value"
  assert_equal "$prefix__first_section__key_three" "single quoted value"
  assert_equal \
    "$prefix__first_section__specifics__another_key" "another quoted value"
  assert_equal "$prefix__second_section__different_key" "5"
  assert_equal "$prefix__second_section__items" \
    "first|second|third/is/a/path.to.file|fourth quoted|fifth single quoted"
  assert_equal "$prefix__another_list" "1|2|3"
}

@test "parsing dotters" {
  local -r dotr="$BATS_TEST_DIRNAME/test_dotfiles/.dot"
  dot_parser "$dotr"
  assert_equal "${dot_parser__mapping[0]}" "home:standard:"
  assert_equal "${dot_parser__mapping[1]}" "home:special:different.format.special"
  assert_equal "${dot_parser__mapping[2]}" "home:another:"
  assert_equal "${dot_parser__mapping[3]}" "config:in_config:"
  assert_equal "${dot_parser__mapping[4]}" "config:as_such:as_such"
  assert_equal "${dot_parser__mapping[5]}" "ignore:dont_traverse_me:"
  assert_equal "${dot_parser__mapping[6]}" "ignore:_bad_dir:"
  assert_equal "${dot_parser__mapping[7]}" "ignore:.weirdo:"
}
