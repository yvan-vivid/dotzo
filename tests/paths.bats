#!/usr/env bats
# vim: ft=sh

load test_helper/bats-support/load
load test_helper/bats-assert/load

load "../lib/paths"

@test "joining" {
  local d
  join_case() {
    local be; be="$1"; shift
    run join_into "$d" "$@"; assert_output "$be"
  }

  for d in ":" "/" "#"; do
    join_case ""
    join_case "" ""
    join_case "abc" "abc"
    join_case "abc${d}def" "abc" "def"
    join_case "ab c${d}d ef" "ab c" "d ef"
    join_case "ab c${d}${d}d ef" "ab c" "" "d ef"
    join_case "ab c${d}.${d}d ef" "ab c" "." "d ef"
    join_case "ab c${d}d ef${d}" "ab c" "d ef" ""
    join_case "ab c${d}d ef${d}${d}" "ab c" "d ef" "" ""
    join_case "ab c${d}d ef${d}${d}${d}" "ab c" "d ef" "" "" ""
    join_case "${d}${d}ab c${d}${d}d ef${d}${d}${d}" "" "" "ab c" "" "d ef" "" "" ""
  done
}

@test "split then join" {
  declare -a buffer
  split_join_case() {
    split_into "/" "buffer" "$1"
    run join_into ":" "${buffer[@]}"
    assert_output "$2"
  }
  
  split_join_case "" ""
  split_join_case "abc" "abc"
  split_join_case "a/bc" "a:bc"
  split_join_case "a//bc" "a::bc"
  split_join_case "a/bc/d e/f" "a:bc:d e:f"
  split_join_case "/a/bc/d e/f" ":a:bc:d e:f"
  split_join_case "/abc///de//f" ":abc:::de::f"
  split_join_case "/abc///de//f/" ":abc:::de::f:"
  split_join_case "/abc///de//f//" ":abc:::de::f::"
  split_join_case "///" ":::"
}

@test "factoring paths - rooted" {
  factors_case() {
    run factor_paths "$1" "$2"
    assert_output "$3"
  }
  
  factors_case "/" "/" "/::"
  factors_case "/abc" "/" "/:abc:"
  factors_case "/" "/abc" "/::abc"
  factors_case "/" "/abc/def" "/::abc/def"
  factors_case "/abc/def" "/" "/:abc/def:"
  factors_case "/abc" "/abc/def" "/abc::def"
  factors_case "/abc/efg" "/abc/def" "/abc:efg:def"
  factors_case "/abc/efg/hij" "/abc/def" "/abc:efg/hij:def"
  factors_case "/abc/efg/hij" "/abc/def" "/abc:efg/hij:def"
}

@test "factoring paths - unrooted" {
  factors_case() {
    run factor_paths "$1" "$2"
    assert_output "$3"
  }

  factors_case "abc" "abc" "abc::"
  factors_case "abc" "abc/def" "abc::def"
  factors_case "abc/efg" "abc/def" "abc:efg:def"
  factors_case "abc/efg/hij" "abc/def" "abc:efg/hij:def"
}

@test "factoring paths - empty" {
  factors_case() {
    run factor_paths "$1" "$2"
    assert_output "$3"
  }

  factors_case "" "" ""
  factors_case "/" "" ""
  factors_case "" "/" ""
  factors_case "/abc" "" ""
  factors_case "" "/abc" ""
  factors_case "abc" "/abc" ""
  factors_case "/abc" "abc" ""
}

@test "normalize paths" {
  local -r d="$BATS_TEST_DIRNAME/path_test_tree"
  normalize_case() {
    cd "$d"
    run normalize "$1"
    assert_output "$2"
  }

  normalize_case "./a/b1/../b1/to_c/./u" "$d/a/b1/to_c/u"
  normalize_case "a///b1/../b1/to_c/.//" "$d/a/b1/to_c"
  normalize_case "../path_test_tree/a/b1/../b1/to_c/" "$d/a/b1/to_c"
  normalize_case "a/b1/../../../path_test_tree/a/b1/to_c/" "$d/a/b1/to_c"
}

@test "relativize paths" {
  local -r d="$BATS_TEST_DIRNAME/path_test_tree"
  relativize_case() {
    cd "$d"
    run relativize "$1" "$2"
    assert_output "$3"
  }

  relativize_case "a/x" "a/x" "x"
  relativize_case "a/x" "a" "x"
  relativize_case "a/x" "a/b1/to_c/u" "../../x"
  relativize_case "a/x" "a/b1/to_c" "../../x"
  relativize_case "a/b1/to_c/to_y" "a" "b1/to_c/to_y"
  relativize_case "a/b1/to_c/to_y" "a/b2" "../b1/to_c/to_y"
  relativize_case "a/b1/to_c/to_y" "a/b2/c/u" "../../b1/to_c/to_y"
}

@test "checking links" {
  cd "$BATS_TEST_DIRNAME/path_test_tree"
  run check_link given "a/b1/to_u" "../b2/c/u"
  assert_success
  run check_link relative "a/b1/to_u" "a/b2/c/u"
  assert_success
  run check_link relative "a/b1/to_u" "a/b2/c"
  assert_failure $check_link__src_diff
  run check_link relative "a/b1/y" "a/b2/c"
  assert_failure $check_link__src_clob
  run check_link relative "a/b1/to_v" "a/b2/c"
  assert_failure $check_link__link_dne
}
