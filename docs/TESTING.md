# F08 — Advanced testing and performance

## Property-based regression checks

Run `bash tests/advanced-smoke.sh`. The test harness generates deterministic
valid templates from a bounded recursive grammar. It computes expected output
separately while generating the templates, instead of trusting a second
execution of the compiler as the oracle.

Each case verifies `--check` emits no output, `--compile` produces valid Bash,
direct rendering and compiled Bash produce exact expected bytes, and repeated
compilation is deterministic. Selected cases test file output and rejected
unexpected block endings. The suite additionally tests 192 alternating nested
blocks and a wide 2,048-line template.

To replay a failing run:

```sh
SHTPL_FUZZ_SEED=20261018 SHTPL_FUZZ_CASES=40 bash tests/advanced-smoke.sh
```

The failing seed, case index and input are printed on errors. The generator
uses its own fixed integer pseudo-random sequence; no nonstandard dependencies
are required. This is bounded generative testing, not a coverage-guided
security fuzzer, and does not make template execution safe for untrusted input.

## Benchmarks

Run `bash tests/benchmark.sh` (requires GNU `/usr/bin/time`). Set
`SHTPL_BENCH_REPETITIONS=5` to change repetitions, up to 20.

The script reports CSV columns for workload size, mode (`check`, `compile`,
`render`), iteration, wall time, maximum resident memory, and output size.
It tests 128, 1,024 and 4,096 source lines without arbitrary performance
cutoffs. Values are diagnostic; runner scheduling and hardware vary.

CI runs on pull requests or manual dispatch. Functional generated checks run
under Ubuntu 22.04, Ubuntu 24.04, and Bash 4.4. Benchmarks run separately on
Ubuntu 24.04 and upload the CSV artifact; slow measurements do not fail CI.
