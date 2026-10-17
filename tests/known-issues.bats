#!/usr/bin/env bats

# Future contracts, deliberately skipped while the legacy engine is unchanged.
# These tests are not counted as passing or as currently supported features.

@test "pending: nested for inside for" {
  skip "F02: arbitrary block nesting is not implemented"
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/for-for"
  [ "$status" -eq 0 ]
}

@test "pending: nested if inside if" {
  skip "F02: arbitrary block nesting is not implemented"
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/if-if"
  [ "$status" -eq 0 ]
}

@test "pending: for-if-for at depth three" {
  skip "F02: arbitrary block nesting is not implemented"
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/for-if-for"
  [ "$status" -eq 0 ]
}

@test "pending: if-for-if at depth three" {
  skip "F02: arbitrary block nesting is not implemented"
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/if-for-if"
  [ "$status" -eq 0 ]
}

@test "pending: multiple command substitutions on one line" {
  skip "Future feature: multiple expansions are not implemented"
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/multiple-commands"
  [ "$status" -eq 0 ]
}

@test "pending: multiple arithmetic expansions on one line" {
  skip "Future feature: multiple expansions are not implemented"
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/multiple-arithmetic"
  [ "$status" -eq 0 ]
}

