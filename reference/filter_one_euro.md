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
  [`replace_na_with()`](http://animovement.dev/aniprocess/reference/replace_na_with.md).

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

[`filter_lowpass()`](http://animovement.dev/aniprocess/reference/filter_lowpass.md)
for a fixed-cutoff Butterworth filter.

## Examples

``` r
t <- seq(0, 2, by = 1 / 60)
x <- ifelse(t < 1, 0, 10) + rnorm(length(t), 0, 0.1)

# beta = 0 is a plain low-pass: smooth, but slow to follow the step
filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.5)
#>   [1] -0.0002893626  0.0017810953  0.0052968762  0.0167453194  0.0145118154
#>   [6]  0.0113963506  0.0112235147  0.0144955108  0.0165771583  0.0138916016
#>  [11]  0.0102086494  0.0075902496  0.0028724150  0.0032603052  0.0001774176
#>  [16] -0.0014626363 -0.0018145746 -0.0119359703 -0.0105920556 -0.0115222311
#>  [21] -0.0096802121 -0.0119511972 -0.0043654879 -0.0081060785 -0.0154969126
#>  [26] -0.0199032408 -0.0138383081 -0.0166429765 -0.0109722038 -0.0108084889
#>  [31] -0.0058279920 -0.0094064672 -0.0067651789 -0.0043715003  0.0007037642
#>  [36]  0.0063731305  0.0121125391  0.0115122713  0.0146965854  0.0156689801
#>  [41]  0.0157276062  0.0218961497  0.0174278920  0.0202308271  0.0149417378
#>  [46]  0.0162941361  0.0227005639  0.0225382978  0.0179778373  0.0237497912
#>  [51]  0.0361815595  0.0296840040  0.0193454597  0.0148202013  0.0186158722
#>  [56]  0.0138476240  0.0092674332  0.0066559590  0.0030033434  0.0097673613
#>  [61]  0.5113656545  0.9844919675  1.4459148730  1.8675934572  2.2751450796
#>  [66]  2.6559541304  3.0292412298  3.3794347815  3.7076810914  4.0239254246
#>  [71]  4.3144431939  4.5902331861  4.8531942586  5.1058725934  5.3445042146
#>  [76]  5.5738358815  5.8001012249  6.0027082805  6.2053134364  6.4109913866
#>  [81]  6.5976187559  6.7576942517  6.9242655112  7.0732908739  7.2268501951
#>  [86]  7.3686884216  7.5053407997  7.6400730852  7.7609913346  7.8759520577
#>  [91]  7.9762151443  8.0789057748  8.1765007658  8.2773934058  8.3687678563
#>  [96]  8.4460631463  8.5219834504  8.5970014012  8.6656347614  8.7322463245
#> [101]  8.7847765533  8.8436052607  8.9034402930  8.9614504299  9.0095975872
#> [106]  9.0578354273  9.1064653231  9.1596036694  9.1932431237  9.2295057780
#> [111]  9.2755009955  9.3150313512  9.3496968576  9.3806413551  9.4139347067
#> [116]  9.4511044521  9.4876746300  9.5150870103  9.5319065284  9.5587664158
#> [121]  9.5813761875

# raising beta keeps the still passages smooth but tracks the step
filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.5, beta = 0.5)
#>   [1] -0.0002893626  0.0022413282  0.0077102329  0.0372778310  0.0302381929
#>   [6]  0.0237181576  0.0225152334  0.0272775225  0.0299271317  0.0251868239
#>  [11]  0.0206163443  0.0162201658  0.0065055740  0.0068755226  0.0002291782
#>  [16] -0.0032259270 -0.0037622732 -0.0325446201 -0.0266362987 -0.0269494999
#>  [21] -0.0217255248 -0.0251935574 -0.0158425456 -0.0204558373 -0.0346335630
#>  [26] -0.0426648481 -0.0319121229 -0.0350437573 -0.0277203364 -0.0265160260
#>  [31] -0.0162439054 -0.0205218858 -0.0151264583 -0.0097681937  0.0027426040
#>  [36]  0.0179810085  0.0336986121  0.0291432318  0.0355561668  0.0353846820
#>  [41]  0.0331784476  0.0477907867  0.0359122191  0.0399617043  0.0310730976
#>  [46]  0.0318625223  0.0429248671  0.0408673704  0.0347273192  0.0427592385
#>  [51]  0.0734635856  0.0590621921  0.0403928738  0.0287819462  0.0339857427
#>  [56]  0.0220227023  0.0094116728  0.0025100295 -0.0071573938  0.0071179290
#>  [61]  7.5731820404  9.4710330645 10.0780847157  9.9602685289 10.0325614756
#>  [66]  9.9587756042 10.0979395444 10.0774894209 10.0120279439 10.0445835639
#>  [71]  9.9359193272  9.8911314265  9.8825291209  9.9083703757  9.9051905498
#>  [76]  9.9285999804 10.0202177992  9.9553584820 10.0064130245 10.1522161632
#>  [81] 10.1562660225 10.0352072877 10.0593708431 10.0168225093 10.0606668731
#>  [86] 10.0655997460 10.0795667289 10.1177336101 10.1053870134 10.0972996534
#>  [91] 10.0590487777 10.0558275464 10.0534080736 10.0804788434 10.0863418117
#>  [96] 10.0650992819 10.0557271136 10.0533968991 10.0482812855 10.0459419311
#> [101] 10.0171736853 10.0112819167 10.0148954907 10.0195397769 10.0101242536
#> [106] 10.0068151167 10.0095061850 10.0179843856 10.0006648057  9.9920310127
#> [111] 10.0024051088 10.0061061202 10.0064214556 10.0045569387 10.0071959888
#> [116] 10.0220427567 10.0435107396 10.0429115462 10.0296747771 10.0329842599
#> [121] 10.0315803676
```
