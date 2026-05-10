# Sunlight and Shadow Analysis for Private Properties

This R project simulates shadow movement and sunlight exposure on a private property based on user-defined objects such as buildings, trees, fences, or sheds.

The script can:

- visualize shadowfall for specific time points
- calculate sunlight exposure over the course of a day
- generate a heatmap showing the sunniest areas of a property

The project uses simple geometric shadow calculations based on:

- object height
- object position
- solar altitude
- solar azimuth

---

# Example Output

## Property Layout

![Property Layout](images/property_plot.png)

## Shadowfall Example

![Shadowfall](images/shadowfall_14h.png)

## Daily Sunlight Heatmap

![Heatmap](images/heatmap_daily.png)

---

# Required Packages

```r
install.packages(c(
  "tidyverse",
  "ggplot2",
  "dplyr",
  "sp",
  "suncalc",
  "patchwork"
))
```

Load packages:

```r
library(tidyverse)
library(ggplot2)
library(dplyr)
library(sp)
library(suncalc)
library(patchwork)
```

---

# Required User Inputs

At the beginning of the script, the user must define:

## 1. Date of Interest

```r
times <- seq(
  as.POSIXct("2025-05-10 04:00", tz = "Europe/Berlin"),
  as.POSIXct("2025-05-10 22:00", tz = "Europe/Berlin"),
  by = "30 min"
)
```

This defines:

- simulated day
- time range
- temporal resolution

---

## 2. Latitude and Longitude

```r
lat <- 53.143
lon <- 8.214
```

These coordinates are used to calculate solar position.

---

## 3. Property Dimensions

```r
coord_fixed(
  xlim = c(0, 25),
  ylim = c(0, 35),
  expand = FALSE
)
```

Units are meters.

The model assumes a simple local coordinate system:

- x-axis = property width
- y-axis = property length

---

# Input Data Structure

The script requires a CSV file containing all shadow-casting objects.

Example file:

```text
example_objects.csv
```

---

# Required Columns

| Column | Description |
|---|---|
| Object | Name of object |
| Form | Shape of object (`Rectangle` or `Circle`) |
| X | X coordinate of object center [m] |
| Y | Y coordinate of object center [m] |
| Length | Length of rectangle [m] |
| Width | Width of rectangle [m] |
| Radius | Radius of circular object [m] |
| Height | Height of object [m] |

---

# Example Input Table

| Object | Form | X | Y | Length | Width | Radius | Height |
|---|---|---|---|---|---|---|---|
| House | Rectangle | 14 | 13 | 10 | 11 | NA | 7 |
| Fence | Rectangle | 12 | 34 | 25 | 0.5 | NA | 2 |
| Birch | Circle | 4 | 4 | NA | NA | 2.5 | 9 |

---

# Coordinate System

The project uses a local coordinate system:

- origin `(0,0)` = lower-left corner of property
- all units are meters
- rectangles are defined by center coordinates plus dimensions
- circles are defined by center coordinates plus radius

---

# How the Script Works

## 1. Solar Position

The package `suncalc` calculates:

- solar altitude
- solar azimuth

for every time point.

---

## 2. Shadow Length

Shadow length is calculated using trigonometry:

```text
Shadow Length = Object Height / tan(Solar Altitude)
```

---

## 3. Shadow Geometry

Each object is shifted according to:

- shadow length
- shadow direction

This creates shadow polygons.

---

## 4. Heatmap Calculation

The property is divided into raster cells.

For every time point:

- the script checks whether a raster cell lies inside a shadow polygon
- sunlight duration is accumulated over the day

---

# Output

The script produces:

## 1. Property Layout Plot

Visualization of all property objects.

---

## 2. Shadowfall Plot

Shadow distribution for a selected time point.

Example:

```r
plot_shadows_at_time("14:00", objects)
```

---

## 3. Sunlight Heatmap

Heatmap showing accumulated sunlight hours over the course of the day.

- yellow = high sunlight exposure
- blue = low sunlight exposure

---

# Current Limitations

This project currently:

- assumes flat terrain
- uses simplified geometric shadow models
- does not include terrain elevation
- does not include seasonal vegetation changes
- does not calculate reflected light
- does not use GIS or LiDAR data

The model is intended as a lightweight spatial simulation tool for private properties and exploratory sunlight analysis.

---

# Typical Applications

- identifying sunny seating areas
- garden planning
- terrace planning
- preliminary solar exposure analysis
- visualization of daily shadow movement

---

# Author

Portfolio project in spatial and environmental data analysis using R.
