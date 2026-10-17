#!/usr/bin/env bats

# F02 nesting and F03 repeated-expansion contracts are active.

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

@test "F03: multiple command substitutions on one line" {
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/multiple-commands"
  [ "$status" -eq 0 ]
}

@test "F03: multiple arithmetic expansions on one line" {
  run bash "$BATS_TEST_DIRNAME/assert-fixture.sh" "pending/multiple-arithmetic"
  [ "$status" -eq 0 ]
}

