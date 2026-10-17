#!/usr/bin/env bats

assert_fixture() {
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "$1"
  if [ "$status" -ne 0 ]; then
    printf '%s\n' "$output"
    return 1
  fi
}

@test "preserves literal text, comments, and blank lines" {
  assert_fixture literals
}

@test "defines and expands scalar variables" {
  assert_fixture variables
}

@test "selects a true if branch" {
  assert_fixture if-true
}

@test "selects an else branch" {
  assert_fixture if-false
}

@test "iterates a for block" {
  assert_fixture for
}

@test "supports a for inside an if" {
  assert_fixture for-in-if
}

@test "supports an if inside a for" {
  assert_fixture if-in-for
}

@test "evaluates one arithmetic and one command substitution per line" {
  assert_fixture expansions
}

@test "renders final input line without a newline" {
  assert_fixture no-eol
}
