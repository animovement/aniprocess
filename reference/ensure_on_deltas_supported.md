# Reject `on_deltas` for the criteria it does not suit.

Unlike the smoothing filters, the masking criteria differ in whether a
displacement is even the right thing to judge. Only `"range"` reads
naturally on differences — "reject implausible single-window
displacements". The rest would compute something defensible but
unexpected, so they say why rather than doing it quietly.

## Usage

``` r
ensure_on_deltas_supported(method, on_deltas, call = rlang::caller_env())
```

## Arguments

- method:

  The criterion, already matched.

- on_deltas:

  The supplied argument.

- call:

  Environment used for the error's call context.

## Value

Invisibly `NULL`. Called for side effects (errors).
