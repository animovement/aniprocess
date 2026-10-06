# Apply the One Euro filter

An adaptive low-pass filter that trades jitter against lag according to
how fast the signal is moving: heavy smoothing while the subject is
nearly still, light smoothing while it moves quickly.

## Usage

``` r
filter_one_euro(
  x,
  sampling_rate,
  min_cutoff = 1,
  beta = 0,
  d_cutoff = 1,
  na_action = c("linear", "spline", "stine", "locf", "value", "error"),
  keep_na = TRUE,
  ...
)
```

## Arguments

- x:

  Numeric vector to filter.

- sampling_rate:

  Sampling rate of the signal in Hz.

- min_cutoff:

  Minimum cutoff frequency in Hz, the cutoff used when the signal is not
  moving. Lower means smoother but laggier. Default `1`.

- beta:

  Speed coefficient. `0` gives a plain low-pass filter at `min_cutoff`;
  larger values raise the cutoff more sharply as the signal speeds up,
  cutting lag. Default `0`.

- d_cutoff:

  Cutoff frequency in Hz for the derivative estimate, which keeps noise
  in the derivative from driving the adaptation. Default `1`.

- na_action:

  Method used to fill `NA` values *before* filtering, so the filter sees
  a complete series. One of `"linear"` (default), `"spline"`, `"stine"`,
  `"locf"`, `"value"`, or `"error"` to abort when `NA`s are present.
  Filling is internal: whether the filled values reach the output is
  controlled by `keep_na`.

- keep_na:

  Logical. If `TRUE` (default), positions that were `NA` in the input
  are `NA` in the output — gaps stay gaps. If `FALSE`, the values used
  to fill those gaps are kept, so the output has **fewer `NA`s than the
  input** and genuinely-missing stretches come back as interpolated
  estimates.

- ...:

  Additional arguments passed to
  [`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md).

## Value

Filtered numeric vector, same length as `x`.

## Details

A fixed low-pass filter forces one compromise on the whole recording.
Set the cutoff low and slow passages come out clean but fast ones lag
behind; set it high and fast passages track well but slow ones jitter.
The One Euro filter (Casiez, Roussel & Vogel, 2012) removes the
compromise by making the cutoff a function of the estimated speed:

\$\$f_c = f\_{c\_{min}} + \beta \|\dot{x}\|\$\$

where \\\dot{x}\\ is itself low-pass filtered, at `d_cutoff`, so that
noise in the derivative does not drive the cutoff around.

Tuning, following the authors' advice, is two-stage:

1.  Set `beta = 0` and lower `min_cutoff` until jitter is acceptable
    while the subject is still.

2.  Raise `beta` until lag is acceptable while it moves quickly.

`min_cutoff` therefore governs the slow-movement end and `beta` the
fast-movement end, and the two can be tuned almost independently.

The filter is recursive, so it needs a complete series: `NA`s are filled
by `na_action` before filtering. With `keep_na = TRUE` (the default)
they are restored afterwards, so the gaps are not silently invented.

## References

Casiez, G., Roussel, N., & Vogel, D. (2012). 1 € Filter: A Simple
Speed-based Low-pass Filter for Noisy Input in Interactive Systems.
*Proceedings of the SIGCHI Conference on Human Factors in Computing
Systems (CHI '12)*, 2527–2530.
[doi:10.1145/2207676.2208639](https://doi.org/10.1145/2207676.2208639)

## See also

[`filter_lowpass()`](https://animovement.dev/aniprocess/reference/filter_lowpass.md)
for a fixed-cutoff Butterworth filter.

## Examples

``` r
t <- seq(0, 2, by = 1 / 60)
x <- ifelse(t < 1, 0, 10) + rnorm(length(t), 0, 0.1)

# beta = 0 is a plain low-pass: smooth, but slow to follow the step
filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.5)
#>   [1]  0.0569722972  0.0621598435  0.0509208525  0.0445085776  0.0391039072
#>   [6]  0.0337693524  0.0219726107  0.0233719000  0.0145876178  0.0137374398
#>  [11]  0.0160043165  0.0142219102  0.0179524663  0.0169313016  0.0128664725
#>  [16]  0.0154422483  0.0125154005  0.0207122786  0.0195908941  0.0228593122
#>  [21]  0.0227427358  0.0066447138 -0.0004829446 -0.0025690250 -0.0012629938
#>  [26] -0.0128563086 -0.0074317512 -0.0100692902 -0.0133142157 -0.0203916734
#>  [31] -0.0266108998 -0.0250066042 -0.0212280539 -0.0306098172 -0.0340840096
#>  [36] -0.0297224515 -0.0304976927 -0.0182065566 -0.0111025159 -0.0075872291
#>  [41] -0.0071854262 -0.0054379654 -0.0086796175 -0.0051230833  0.0024965783
#>  [46]  0.0077629376  0.0033304202 -0.0048899614 -0.0051922516 -0.0027402796
#>  [51]  0.0041178959 -0.0026476943 -0.0007029734  0.0004937748  0.0064096989
#>  [56]  0.0059519208  0.0038780540 -0.0020208399 -0.0044947050 -0.0060728091
#>  [61]  0.5034717224  0.9881415365  1.4356946592  1.8566165876  2.2519721158
#>  [66]  2.6400338563  3.0008008376  3.3604113353  3.6863558854  4.0010423266
#>  [71]  4.3184767503  4.5956420326  4.8660646728  5.1159948961  5.3607269740
#>  [76]  5.5872078293  5.8071497151  6.0142867712  6.2067076522  6.3954980607
#>  [81]  6.5797727516  6.7578759633  6.9123570696  7.0647399658  7.2165517101
#>  [86]  7.3494976349  7.4687921683  7.5900751634  7.7051678403  7.8195828643
#>  [91]  7.9260601405  8.0304002530  8.1262956467  8.2213827096  8.3080562742
#>  [96]  8.3981597881  8.4741903564  8.5515528013  8.6192173503  8.6889527435
#> [101]  8.7539460606  8.8075618468  8.8661736854  8.9284590240  8.9851635385
#> [106]  9.0363691734  9.0783820235  9.1300543387  9.1737323129  9.2125952474
#> [111]  9.2599422217  9.2929345083  9.3296237224  9.3693553600  9.4037292544
#> [116]  9.4318689612  9.4580543377  9.4867856628  9.5148753129  9.5391051394
#> [121]  9.5685967438

# raising beta keeps the still passages smooth but tracks the step
filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.5, beta = 0.5)
#>   [1]  0.0569722972  0.0649992319  0.0456584230  0.0318853984  0.0195774939
#>   [6]  0.0072098954 -0.0302298915 -0.0181600581 -0.0411526129 -0.0352775849
#>  [11] -0.0237324729 -0.0232833445 -0.0141058251 -0.0132322333 -0.0176811546
#>  [16] -0.0125860672 -0.0147042994  0.0011565969  0.0009214131  0.0091149637
#>  [21]  0.0102052113 -0.0172081028 -0.0307594309 -0.0320476923 -0.0269399949
#>  [26] -0.0552357213 -0.0411050068 -0.0429251045 -0.0460968053 -0.0591945686
#>  [31] -0.0706754396 -0.0624183017 -0.0539205664 -0.0712071297 -0.0744913108
#>  [36] -0.0648503396 -0.0635233381 -0.0341370493 -0.0124413178 -0.0019949061
#>  [41] -0.0016535752  0.0023841393 -0.0057974310  0.0026109023  0.0242382147
#>  [46]  0.0375576745  0.0229681641  0.0098248342  0.0085000275  0.0110496415
#>  [51]  0.0235197349  0.0147444723  0.0160801067  0.0165335082  0.0255267131
#>  [56]  0.0233503263  0.0198628867  0.0095471335  0.0040574466  0.0001975513
#>  [61]  7.7090189710  9.6839871574  9.9134345020  9.9001158230  9.8292809872
#>  [66]  9.9876934751  9.9209460103 10.1295952921  9.9879771185 10.0025003746
#>  [71] 10.2378919993 10.0350591909 10.0326590183  9.9574303163  9.9966254611
#>  [76]  9.9566224983  9.9800163153  9.9758070366  9.9380257351  9.9624314766
#>  [81] 10.0145807923 10.0692370357 10.0011191561  9.9931156223 10.0307835450
#>  [86]  9.9929099219  9.9421395136  9.9354579540  9.9300142713  9.9430618275
#>  [91]  9.9458381861  9.9592694888  9.9590237880  9.9723422003  9.9709296922
#>  [96]  9.9975190225  9.9865552577  9.9931083401  9.9827363381  9.9876471879
#> [101]  9.9885856380  9.9761356373  9.9768810784  9.9925174978 10.0018197580
#> [106] 10.0033134842  9.9930648158 10.0067741052 10.0068950382 10.0023234750
#> [111] 10.0222394926 10.0130240176 10.0146381449 10.0278641148 10.0316865475
#> [116] 10.0256237013 10.0204930850 10.0216562861 10.0241026588 10.0224623898
#> [121] 10.0332673430
```
