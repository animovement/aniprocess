# Filter coordinates outside a region of interest (ROI)

Filters out coordinates that fall outside a specified region of interest
by setting them to NA. The ROI can be either rectangular (defined by
min/max coordinates) or circular (defined by center and radius).

## Usage

``` r
filter_na_roi(
  data,
  x_min = NULL,
  x_max = NULL,
  y_min = NULL,
  y_max = NULL,
  x_center = NULL,
  y_center = NULL,
  radius = NULL
)
```

## Arguments

- data:

  A data frame containing 'x' and 'y' coordinates

- x_min:

  Minimum x-coordinate for rectangular ROI

- x_max:

  Maximum x-coordinate for rectangular ROI

- y_min:

  Minimum y-coordinate for rectangular ROI

- y_max:

  Maximum y-coordinate for rectangular ROI

- x_center:

  x-coordinate of circle center for circular ROI

- y_center:

  y-coordinate of circle center for circular ROI

- radius:

  Radius of circular ROI

## Value

A data frame with coordinates outside ROI set to NA

## Examples

``` r
# Create sample data
sample_data <- expand.grid(
  x = seq(0, 100, by = 10),
  y = seq(0, 100, by = 10)
) |> as.data.frame()

# Rectangular ROI example
sample_data |>
  filter_na_roi(x_min = 20, x_max = 80, y_min = 20, y_max = 80)
#>      x  y
#> 1   NA NA
#> 2   NA NA
#> 3   NA NA
#> 4   NA NA
#> 5   NA NA
#> 6   NA NA
#> 7   NA NA
#> 8   NA NA
#> 9   NA NA
#> 10  NA NA
#> 11  NA NA
#> 12  NA NA
#> 13  NA NA
#> 14  NA NA
#> 15  NA NA
#> 16  NA NA
#> 17  NA NA
#> 18  NA NA
#> 19  NA NA
#> 20  NA NA
#> 21  NA NA
#> 22  NA NA
#> 23  NA NA
#> 24  NA NA
#> 25  20 20
#> 26  30 20
#> 27  40 20
#> 28  50 20
#> 29  60 20
#> 30  70 20
#> 31  80 20
#> 32  NA NA
#> 33  NA NA
#> 34  NA NA
#> 35  NA NA
#> 36  20 30
#> 37  30 30
#> 38  40 30
#> 39  50 30
#> 40  60 30
#> 41  70 30
#> 42  80 30
#> 43  NA NA
#> 44  NA NA
#> 45  NA NA
#> 46  NA NA
#> 47  20 40
#> 48  30 40
#> 49  40 40
#> 50  50 40
#> 51  60 40
#> 52  70 40
#> 53  80 40
#> 54  NA NA
#> 55  NA NA
#> 56  NA NA
#> 57  NA NA
#> 58  20 50
#> 59  30 50
#> 60  40 50
#> 61  50 50
#> 62  60 50
#> 63  70 50
#> 64  80 50
#> 65  NA NA
#> 66  NA NA
#> 67  NA NA
#> 68  NA NA
#> 69  20 60
#> 70  30 60
#> 71  40 60
#> 72  50 60
#> 73  60 60
#> 74  70 60
#> 75  80 60
#> 76  NA NA
#> 77  NA NA
#> 78  NA NA
#> 79  NA NA
#> 80  20 70
#> 81  30 70
#> 82  40 70
#> 83  50 70
#> 84  60 70
#> 85  70 70
#> 86  80 70
#> 87  NA NA
#> 88  NA NA
#> 89  NA NA
#> 90  NA NA
#> 91  20 80
#> 92  30 80
#> 93  40 80
#> 94  50 80
#> 95  60 80
#> 96  70 80
#> 97  80 80
#> 98  NA NA
#> 99  NA NA
#> 100 NA NA
#> 101 NA NA
#> 102 NA NA
#> 103 NA NA
#> 104 NA NA
#> 105 NA NA
#> 106 NA NA
#> 107 NA NA
#> 108 NA NA
#> 109 NA NA
#> 110 NA NA
#> 111 NA NA
#> 112 NA NA
#> 113 NA NA
#> 114 NA NA
#> 115 NA NA
#> 116 NA NA
#> 117 NA NA
#> 118 NA NA
#> 119 NA NA
#> 120 NA NA
#> 121 NA NA

# Circular ROI example
sample_data |>
  filter_na_roi(x_center = 50, y_center = 50, radius = 25)
#>      x  y
#> 1   NA NA
#> 2   NA NA
#> 3   NA NA
#> 4   NA NA
#> 5   NA NA
#> 6   NA NA
#> 7   NA NA
#> 8   NA NA
#> 9   NA NA
#> 10  NA NA
#> 11  NA NA
#> 12  NA NA
#> 13  NA NA
#> 14  NA NA
#> 15  NA NA
#> 16  NA NA
#> 17  NA NA
#> 18  NA NA
#> 19  NA NA
#> 20  NA NA
#> 21  NA NA
#> 22  NA NA
#> 23  NA NA
#> 24  NA NA
#> 25  NA NA
#> 26  NA NA
#> 27  NA NA
#> 28  NA NA
#> 29  NA NA
#> 30  NA NA
#> 31  NA NA
#> 32  NA NA
#> 33  NA NA
#> 34  NA NA
#> 35  NA NA
#> 36  NA NA
#> 37  NA NA
#> 38  40 30
#> 39  50 30
#> 40  60 30
#> 41  NA NA
#> 42  NA NA
#> 43  NA NA
#> 44  NA NA
#> 45  NA NA
#> 46  NA NA
#> 47  NA NA
#> 48  30 40
#> 49  40 40
#> 50  50 40
#> 51  60 40
#> 52  70 40
#> 53  NA NA
#> 54  NA NA
#> 55  NA NA
#> 56  NA NA
#> 57  NA NA
#> 58  NA NA
#> 59  30 50
#> 60  40 50
#> 61  50 50
#> 62  60 50
#> 63  70 50
#> 64  NA NA
#> 65  NA NA
#> 66  NA NA
#> 67  NA NA
#> 68  NA NA
#> 69  NA NA
#> 70  30 60
#> 71  40 60
#> 72  50 60
#> 73  60 60
#> 74  70 60
#> 75  NA NA
#> 76  NA NA
#> 77  NA NA
#> 78  NA NA
#> 79  NA NA
#> 80  NA NA
#> 81  NA NA
#> 82  40 70
#> 83  50 70
#> 84  60 70
#> 85  NA NA
#> 86  NA NA
#> 87  NA NA
#> 88  NA NA
#> 89  NA NA
#> 90  NA NA
#> 91  NA NA
#> 92  NA NA
#> 93  NA NA
#> 94  NA NA
#> 95  NA NA
#> 96  NA NA
#> 97  NA NA
#> 98  NA NA
#> 99  NA NA
#> 100 NA NA
#> 101 NA NA
#> 102 NA NA
#> 103 NA NA
#> 104 NA NA
#> 105 NA NA
#> 106 NA NA
#> 107 NA NA
#> 108 NA NA
#> 109 NA NA
#> 110 NA NA
#> 111 NA NA
#> 112 NA NA
#> 113 NA NA
#> 114 NA NA
#> 115 NA NA
#> 116 NA NA
#> 117 NA NA
#> 118 NA NA
#> 119 NA NA
#> 120 NA NA
#> 121 NA NA
```
