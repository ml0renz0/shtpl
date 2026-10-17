#!/usr/bin/env bats

@test "compilation does not execute template commands" {
  marker="$BATS_TEST_TMPDIR/compile-effect"
  template="$BATS_TEST_TMPDIR/compile-effect.tpl"
  generated="$BATS_TEST_TMPDIR/compiled.sh"

  printf 'value=$(touch %q; printf OK)\n' "$marker" > "$template"
  run bash "$BATS_TEST_DIRNAME/../shtpl" --compile < "$template"
  [ "$status" -eq 0 ]
  [ ! -e "$marker" ]

  printf '%s\n' "$output" > "$generated"
  run bash "$generated"
  [ "$status" -eq 0 ]
  [ "$output" = 'value=OK' ]
  [ -f "$marker" ]
}

@test "compiler rejects unmatched block endings" {
  run bash "$BATS_TEST_DIRNAME/../shtpl" --compile <<< '{% endif %}'
  [ "$status" -eq 2 ]
  [[ "$output" == *'unexpected endif at line 1'* ]]
}

@test "compiled Bash preserves the nine golden fixtures" {
  run bash "$BATS_TEST_DIRNAME/compile-smoke.sh"
  if [ "$status" -ne 0 ]; then
    printf '%s\n' "$output"
    return 1
  fi
}
