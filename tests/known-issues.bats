#!/usr/bin/env bats

# F02 nesting contracts are active. F03 expansion contracts remain skipped.

@test "F02: nested for inside for" {
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/for-for"
  [ "$status" -eq 0 ]
}

@test "F02: nested if inside if" {
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/if-if"
  [ "$status" -eq 0 ]
}

@test "F02: for-if-for at depth three" {
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/for-if-for"
  [ "$status" -eq 0 ]
}

@test "F02: if-for-if at depth three" {
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

