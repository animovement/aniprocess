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
#>   [1] -0.0072655731 -0.0070239056  0.0012091908  0.0011772668 -0.0021064315
#>   [6]  0.0072461013  0.0110067734  0.0164249015  0.0185932236  0.0179604822
#>  [11]  0.0106496802  0.0094912376  0.0109295236  0.0076867327  0.0084118479
#>  [16]  0.0047848434  0.0024844401 -0.0090568582 -0.0117484765 -0.0138080553
#>  [21] -0.0095867296 -0.0103446496 -0.0064701670 -0.0091103880 -0.0081093513
#>  [26] -0.0058549809 -0.0085980012 -0.0029761206 -0.0043341514  0.0029331373
#>  [31] -0.0015270378 -0.0124873610 -0.0132358134 -0.0107032818 -0.0053339055
#>  [36] -0.0037803562  0.0024154641  0.0009544613 -0.0025674340 -0.0098444687
#>  [41]  0.0029017658  0.0055899163 -0.0002144704  0.0060093469  0.0024629870
#>  [46]  0.0016082048 -0.0048110672 -0.0026047527 -0.0120922119 -0.0062439166
#>  [51] -0.0100180153 -0.0126920874 -0.0128224634 -0.0192317771 -0.0152532123
#>  [56] -0.0140544992 -0.0211680784 -0.0185583405 -0.0143875911 -0.0137113353
#>  [61]  0.4931109353  0.9765047591  1.4236833561  1.8432203917  2.2509557633
#>  [66]  2.6369585972  3.0041112212  3.3539607712  3.6828428882  3.9966108400
#>  [71]  4.3044019256  4.5780233803  4.8524990540  5.1113428999  5.3517035324
#>  [76]  5.5768669525  5.8021108896  6.0132425482  6.1997613211  6.3918143274
#>  [81]  6.5719746844  6.7339928963  6.8966718476  7.0560887233  7.2061102782
#>  [86]  7.3395969100  7.4727079012  7.5965313850  7.7149684902  7.8306105197
#>  [91]  7.9408860389  8.0482566509  8.1418139734  8.2405848195  8.3316519783
#>  [96]  8.4198691124  8.4924653851  8.5693637805  8.6402094154  8.7092590536
#> [101]  8.7751229561  8.8374831519  8.8974563191  8.9517112082  9.0061485018
#> [106]  9.0586648623  9.1046297840  9.1485675400  9.1836029926  9.2248380319
#> [111]  9.2579549133  9.2968073500  9.3280378751  9.3553433616  9.3912206587
#> [116]  9.4182971219  9.4420552435  9.4656501372  9.4973431604  9.5266011401
#> [121]  9.5542608490

# raising beta keeps the still passages smooth but tracks the step
filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.5, beta = 0.5)
#>   [1] -0.0072655731 -0.0070175703  0.0084266469  0.0077395035  0.0029873455
#>   [6]  0.0229980471  0.0300681334  0.0419899520  0.0443238994  0.0399537116
#>  [11]  0.0287929217  0.0265714952  0.0272386085  0.0219140566  0.0219361607
#>  [16]  0.0146272372  0.0092852454 -0.0256471812 -0.0311316264 -0.0342742298
#>  [21] -0.0226261895 -0.0228580579 -0.0157745416 -0.0195699771 -0.0172571355
#>  [26] -0.0140386519 -0.0173466426 -0.0096601660 -0.0108236844  0.0036162377
#>  [31] -0.0025058790 -0.0223075184 -0.0227665585 -0.0185925348 -0.0113124675
#>  [36] -0.0086602089  0.0044770072  0.0016752145 -0.0031444230 -0.0136500132
#>  [41]  0.0114436012  0.0161427702  0.0076683817  0.0187550571  0.0129286152
#>  [46]  0.0112613786  0.0006386386  0.0031312425 -0.0187618266 -0.0093988897
#>  [51] -0.0160324692 -0.0207651894 -0.0202561194 -0.0346302807 -0.0261065525
#>  [56] -0.0234161855 -0.0377587920 -0.0318692676 -0.0263317690 -0.0250548156
#>  [61]  7.6790688134  9.6532967813  9.8921298108  9.8648837170  9.9921495196
#>  [66] 10.0042567713 10.0125718533 10.0281218857  9.9863652291  9.9881098505
#>  [71] 10.1079056124  9.9325146779 10.0237196338 10.0405887693  9.9903872033
#>  [76]  9.9362814096 10.0149304160 10.0286732008  9.9224354045  9.9762938498
#>  [81]  9.9899771007  9.9360956667  9.9579180821 10.0042219516 10.0253365484
#>  [86]  9.9877887247  9.9949335411  9.9868347458  9.9846121931  9.9966823040
#>  [91] 10.0075910610 10.0277150628 10.0090939608 10.0326345536 10.0400979409
#>  [96] 10.0527460927 10.0270367720 10.0285947561 10.0241431180 10.0246078563
#> [101] 10.0255842810 10.0259043907 10.0277577864 10.0239972001 10.0260851224
#> [106] 10.0296475354 10.0256878363 10.0229848766 10.0102155902 10.0103709007
#> [111]  9.9983857565 10.0018417080  9.9940163413  9.9794684868  9.9886343641
#> [116]  9.9831322147  9.9727207004  9.9656033547  9.9774662094  9.9834417477
#> [121]  9.9904574684
```
