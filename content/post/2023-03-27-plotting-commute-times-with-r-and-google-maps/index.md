---
title: "Plotting commute times with R and Google Maps"
author: ~
date: '2023-01-27'
slug: plotting-commute-times-with-r-and-google-maps
category: code
tags:
    - R
featured: "/img/featured/unimelb-commute-header.webp"
output: hugodown::md_document
rmd_hash: 42ab42af6f2e3e29

---

I'm house-hunting, and while I'd love to buy a 5-bedroom house with a pool 10 minutes walk from Flinders Street Station I probably can't afford that. So I need to take a broader look at Melbourne.

One of the main constraints is commute time. I built a choropleth of commute times to the University of Melbourne and put it on top of a map of Melbourne.

The rough idea is to create a fine hexagonal grid across the city using the `sf` package, and then to pass the centre of each hexagon through the Google Maps Directions Matrix API with the help of the (Melbourne-made) `googleway` package. The results are plotted with `leaflet` and [hosted for free on Netlify](https://unimelb-commutes.netlify.app/):

<div class="highlight">

<iframe src="https://unimelb-commutes.netlify.app/" height="500px" width="100%" data-external="1"></iframe>

</div>

A warning if you want to recreate this for your own commute: the Distance Matrix API can end up costing a fair bit if you exceed the free tier. The above plot uses roughly 16K hexagons, although this can be adjusted by making the hexagons larger or querying fewer suburbs. Be sure to [review the API pricing](https://mapsplatform.google.com/pricing/). I'm not responsible for any API charges you incur.

I am grateful to Belinda Maher, from whom I stole this idea.

## Shape files and grids

The starting point a shape file for the Melbourne metropolitan area which I obtained from [Plan Melbourne](https://www.planmelbourne.vic.gov.au/maps/spatial-data). It's a simple polygon that outlines the region.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>metro</span> <span class='o'>&lt;-</span> <span class='nf'>sf</span><span class='nf'>::</span><span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_read.html'>read_sf</a></span><span class='o'>(</span><span class='s'>"Administrative/Metropolitan region_region.shp"</span><span class='o'>)</span></span>
<span><span class='nf'><a href='https://rdrr.io/r/graphics/plot.default.html'>plot</a></span><span class='o'>(</span><span class='nv'>metro</span>, main <span class='o'>=</span> <span class='s'>"Melbourne"</span><span class='o'>)</span></span>
</code></pre>
<img src="figs/melbourne-metro-1.png" width="700px" style="display: block; margin: auto;" />

</div>

The next step is to lay a grid of hexagons over the area. The centre of each hexagon will be used to determine commute time. More polygons means more granularity, but also a greater API cost.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nf'>sf</span><span class='nf'>::</span><span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_make_grid.html'>st_make_grid</a></span><span class='o'>(</span><span class='nv'>metro</span>, cellsize <span class='o'>=</span> <span class='m'>0.1</span>, square <span class='o'>=</span> <span class='kc'>FALSE</span><span class='o'>)</span><span class='o'>[</span><span class='nv'>metro</span><span class='o'>]</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://rdrr.io/r/graphics/plot.default.html'>plot</a></span><span class='o'>(</span><span class='o'>)</span></span>
<span><span class='c'>#&gt; st_as_s2(): dropping Z and/or M coordinate</span></span>
<span></span></code></pre>
<img src="figs/melbourne-metro-grid-example-1.png" width="700px" style="display: block; margin: auto;" />

</div>

These hexagons are a little too large for a useful map. I'll go with something much smaller. This covers the Melbourne metropolitan area with 170,000 hexagons:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>metro_grid</span> <span class='o'>&lt;-</span> <span class='nf'>sf</span><span class='nf'>::</span><span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_make_grid.html'>st_make_grid</a></span><span class='o'>(</span><span class='nv'>metro</span>, cellsize <span class='o'>=</span> <span class='m'>0.0025</span>, square <span class='o'>=</span> <span class='kc'>FALSE</span><span class='o'>)</span><span class='o'>[</span><span class='nv'>metro</span><span class='o'>]</span></span>
<span><span class='c'>#&gt; st_as_s2(): dropping Z and/or M coordinate</span></span>
<span></span><span><span class='nv'>metro_grid</span></span>
<span><span class='c'>#&gt; Geometry set for 170661 features </span></span>
<span><span class='c'>#&gt; Geometry type: POLYGON</span></span>
<span><span class='c'>#&gt; Dimension:     XY</span></span>
<span><span class='c'>#&gt; Bounding box:  xmin: 144.4428 ymin: -38.50138 xmax: 146.1941 ymax: -37.38781</span></span>
<span><span class='c'>#&gt; Geodetic CRS:  GDA94</span></span>
<span><span class='c'>#&gt; First 5 geometries:</span></span>
<span></span><span><span class='c'>#&gt; POLYGON ((144.4441 -37.86485, 144.4428 -37.8641...</span></span>
<span></span><span><span class='c'>#&gt; POLYGON ((144.4441 -37.86052, 144.4428 -37.8598...</span></span>
<span></span><span><span class='c'>#&gt; POLYGON ((144.4453 -37.86268, 144.4441 -37.8619...</span></span>
<span></span><span><span class='c'>#&gt; POLYGON ((144.4453 -37.85835, 144.4441 -37.8576...</span></span>
<span></span><span><span class='c'>#&gt; POLYGON ((144.4453 -37.85402, 144.4441 -37.8533...</span></span>
<span></span></code></pre>

</div>

There are three ways to go from here:

1.  if your budget is unlimited, calculate the commute time for each suburb in
2.  a search method. Starting with the hexagon containing the commute destination, calculate commute time. Then calculate the commute time for the neighbouring hexagons of that hexagon. When a hexagon has a commute time over a certain limit (say, 1 hour), stop computing the commute times of its neighbours.
3.  a suburb-by-suburb method. Using a shape file of suburbs, calculate commute time for the hexagons in each suburb one at a time, manually.

I went with the suburb-by-suburb option here because I wanted to explore and get an idea of where I should be house-hunting. I used [Melbourne localities provided by data.gov.au](https://data.gov.au/data/dataset/af33dd8c-0534-4e18-9245-fc64440f742e) (the GDA94 version matches that of the Melbourne metro shape file). A quick function helps me get the hexagons in `metro_grid` that overlap any part of a suburb:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>localities</span> <span class='o'>&lt;-</span> <span class='nf'>sf</span><span class='nf'>::</span><span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_read.html'>read_sf</a></span><span class='o'>(</span><span class='s'>"vic_localities/vic_localities.shp"</span><span class='o'>)</span></span>
<span></span>
<span><span class='nv'>suburb_grid</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>metro_grid</span>, <span class='nv'>localities</span>, <span class='nv'>suburb</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nf'>assertthat</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/assertthat/man/assert_that.html'>assert_that</a></span><span class='o'>(</span><span class='nv'>suburb</span> <span class='o'><a href='https://rdrr.io/r/base/match.html'>%in%</a></span> <span class='nv'>localities</span><span class='o'>$</span><span class='nv'>LOC_NAME</span><span class='o'>)</span></span>
<span>  <span class='nv'>suburb_shp</span> <span class='o'>&lt;-</span> <span class='nv'>localities</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span><span class='nv'>LOC_NAME</span> <span class='o'>==</span> <span class='nv'>suburb</span><span class='o'>)</span></span>
<span>  <span class='nv'>grid_in_suburb</span> <span class='o'>&lt;-</span> <span class='nv'>metro_grid</span><span class='o'>[</span><span class='nv'>suburb_shp</span><span class='o'>]</span></span>
<span>  <span class='nf'>assertthat</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/assertthat/man/assert_that.html'>assert_that</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/length.html'>length</a></span><span class='o'>(</span><span class='nv'>grid_in_suburb</span><span class='o'>)</span> <span class='o'>&gt;</span> <span class='m'>0</span><span class='o'>)</span></span>
<span>  <span class='nv'>grid_in_suburb</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

The idea of taking a main set of hexagons (`metro_grid`) and then finding its intersection with a particular suburb is so that the hexagons in neighbouring suburbs tessellate.

## Querying the Distance Matrix API

For each hexagon I take its centre and use it as the origin of a Google Maps Distance Matrix query. The destination is a fixed location that represents the input of my commute. Each query uses only public transport and asks for an arrival before 9am on a Monday to capture the typical workday commute. I'm using the following constants:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>workplace</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='m'>144.9580</span>, <span class='o'>-</span><span class='m'>37.8000</span><span class='o'>)</span></span>
<span><span class='nv'>monday_morning</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/as.POSIXlt.html'>as.POSIXct</a></span><span class='o'>(</span><span class='s'>"2023-01-30 09:00:00"</span>, tz <span class='o'>=</span> <span class='s'>"Australia/Melbourne"</span><span class='o'>)</span></span></code></pre>

</div>

I also need a helper function that converts a given set of hexagons into a matrix containing the coordinates of their centroids.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>polygon_centroids</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>polygons</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>polygons</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>sf</span><span class='nf'>::</span><span class='nf'><a href='https://r-spatial.github.io/sf/reference/geos_unary.html'>st_centroid</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>sf</span><span class='nf'>::</span><span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_coordinates.html'>st_coordinates</a></span><span class='o'>(</span><span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

I use the `googleway` package to query the Distance Matrix API. I have a "GOOGLE_MAPS_API_KEY" environment variable defined with my API key. Follow [the instructions provided by Google](https://developers.google.com/maps/documentation/javascript/get-api-key), and be sure to enable the Distance Matrix API.

There's an annoyance here in that Google expect latitude and longitude in a different order to the polygons I'm using. In my function I have a little hack for calculating `rev_origin`, which is the given `origin` but flipped. The origin is either a matrix of coordinates given by `polygon_centroids` or a vector representing a single origin point.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>query_distance_matrix</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span></span>
<span>    <span class='nv'>origin</span>,</span>
<span>    <span class='nv'>destination</span> <span class='o'>=</span> <span class='nv'>workplace</span>,</span>
<span>    <span class='nv'>arrival_time</span> <span class='o'>=</span> <span class='nv'>monday_morning</span></span>
<span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>rev_origin</span> <span class='o'>&lt;-</span> <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/matrix.html'>is.matrix</a></span><span class='o'>(</span><span class='nv'>origin</span><span class='o'>)</span> <span class='o'>&amp;&amp;</span> <span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='o'>(</span><span class='nv'>origin</span><span class='o'>)</span> <span class='o'>==</span> <span class='m'>1</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>    <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='nv'>origin</span><span class='o'>[</span><span class='m'>1</span>,<span class='m'>2</span><span class='o'>]</span>, <span class='nv'>origin</span><span class='o'>[</span><span class='m'>1</span>,<span class='m'>1</span><span class='o'>]</span><span class='o'>)</span></span>
<span>  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/matrix.html'>is.matrix</a></span><span class='o'>(</span><span class='nv'>origin</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>    <span class='nf'><a href='https://rdrr.io/r/base/as.data.frame.html'>as.data.frame</a></span><span class='o'>(</span><span class='nv'>origin</span><span class='o'>[</span>, <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='m'>2</span>, <span class='m'>1</span><span class='o'>)</span><span class='o'>]</span><span class='o'>)</span></span>
<span>  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='o'>&#123;</span></span>
<span>    <span class='nf'><a href='https://rdrr.io/r/base/rev.html'>rev</a></span><span class='o'>(</span><span class='nv'>origin</span><span class='o'>)</span></span>
<span>  <span class='o'>&#125;</span></span>
<span>  <span class='nv'>response</span> <span class='o'>&lt;-</span> <span class='nf'>googleway</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/googleway/man/google_distance.html'>google_distance</a></span><span class='o'>(</span></span>
<span>    origins <span class='o'>=</span> <span class='nv'>rev_origin</span>,</span>
<span>    destinations <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/rev.html'>rev</a></span><span class='o'>(</span><span class='nv'>destination</span><span class='o'>)</span>,</span>
<span>    mode <span class='o'>=</span> <span class='s'>"transit"</span>,</span>
<span>    arrival_time <span class='o'>=</span> <span class='nv'>arrival_time</span>,</span>
<span>    units <span class='o'>=</span> <span class='s'>"metric"</span>,</span>
<span>    key <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/Sys.getenv.html'>Sys.getenv</a></span><span class='o'>(</span><span class='s'>"GOOGLE_MAPS_API_KEY"</span><span class='o'>)</span></span>
<span>  <span class='o'>)</span></span>
<span>  <span class='kr'>if</span> <span class='o'>(</span><span class='nv'>response</span><span class='o'>$</span><span class='nv'>status</span> <span class='o'>!=</span> <span class='s'>"OK"</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>    <span class='kr'><a href='https://rdrr.io/r/base/stop.html'>stop</a></span><span class='o'>(</span><span class='nv'>response</span><span class='o'>$</span><span class='nv'>error_message</span><span class='o'>)</span></span>
<span>  <span class='o'>&#125;</span></span>
<span>  <span class='nv'>response</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

I also need some helper functions for extracting useful information from the raw response. These provide `NA` values when Google cannot find a route, which is likely to happen for hexagons that fall on areas like airport runways.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>dm_origin_address</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span> <span class='nv'>response</span><span class='o'>$</span><span class='nv'>origin_addresses</span></span>
<span><span class='nv'>dm_matrix_response</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span> <span class='nv'>response</span><span class='o'>$</span><span class='nv'>rows</span><span class='o'>$</span><span class='nv'>elements</span></span>
<span><span class='nv'>dm_distance</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>response</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>dm_matrix_response</span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>purrr</span><span class='nf'>::</span><span class='nf'><a href='https://purrr.tidyverse.org/reference/map.html'>map_int</a></span><span class='o'>(</span></span>
<span>    <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='nf'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='o'>(</span><span class='nv'>x</span><span class='o'>$</span><span class='nv'>status</span> <span class='o'>==</span> <span class='s'>"OK"</span>, <span class='nv'>x</span><span class='o'>$</span><span class='nv'>distance</span><span class='o'>$</span><span class='nv'>value</span>, <span class='kc'>NA_integer_</span><span class='o'>)</span></span>
<span>  <span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span>
<span><span class='nv'>dm_time</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>response</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>dm_matrix_response</span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>purrr</span><span class='nf'>::</span><span class='nf'><a href='https://purrr.tidyverse.org/reference/map.html'>map_int</a></span><span class='o'>(</span></span>
<span>    <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='nf'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='o'>(</span><span class='nv'>x</span><span class='o'>$</span><span class='nv'>status</span> <span class='o'>==</span> <span class='s'>"OK"</span>, <span class='nv'>x</span><span class='o'>$</span><span class='nv'>duration</span><span class='o'>$</span><span class='nv'>value</span>, <span class='kc'>NA_integer_</span><span class='o'>)</span></span>
<span>  <span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

## Gathering commute data

A single query to the Distance Matrix API can contain at most 25 origins, so this function must batch the requests. Each batch of 25 (or fewer) is queried against the API. The results are turned into a data frame alongside the original hexagons, the coordinates of their centres, and the data from the helper functions I've defined.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>commute_facts</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>polygons</span>, <span class='nv'>destination</span> <span class='o'>=</span> <span class='nv'>workplace</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>batch_size</span> <span class='o'>&lt;-</span> <span class='m'>25</span></span>
<span>  <span class='nv'>n_polys</span> <span class='o'>&lt;-</span> <span class='nv'>polygons</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'><a href='https://rdrr.io/r/base/length.html'>length</a></span><span class='o'>(</span><span class='o'>)</span></span>
<span>  <span class='nv'>batches</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/Round.html'>ceiling</a></span><span class='o'>(</span><span class='nv'>n_polys</span> <span class='o'>/</span> <span class='nv'>batch_size</span><span class='o'>)</span></span>
<span></span>
<span>  <span class='nv'>query_batch_number</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>batch_number</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>    <span class='nv'>batch_start</span> <span class='o'>&lt;-</span> <span class='nv'>batch_size</span> <span class='o'>*</span> <span class='o'>(</span><span class='nv'>batch_number</span> <span class='o'>-</span> <span class='m'>1</span><span class='o'>)</span> <span class='o'>+</span> <span class='m'>1</span></span>
<span>    <span class='nv'>batch_end</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/Extremes.html'>min</a></span><span class='o'>(</span><span class='nv'>batch_start</span> <span class='o'>+</span> <span class='nv'>batch_size</span> <span class='o'>-</span> <span class='m'>1</span>, <span class='nv'>n_polys</span><span class='o'>)</span></span>
<span>    <span class='nv'>polygons_in_batch</span> <span class='o'>&lt;-</span> <span class='nv'>polygons</span><span class='o'>[</span><span class='nv'>batch_start</span><span class='o'>:</span><span class='nv'>batch_end</span><span class='o'>]</span></span>
<span>    <span class='nv'>coords_in_batch</span> <span class='o'>&lt;-</span> <span class='nv'>polygons_in_batch</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>polygon_centroids</span><span class='o'>(</span><span class='o'>)</span></span>
<span>    <span class='nv'>response</span> <span class='o'>&lt;-</span> <span class='nf'>query_distance_matrix</span><span class='o'>(</span><span class='nv'>coords_in_batch</span>, destination <span class='o'>=</span> <span class='nv'>destination</span><span class='o'>)</span></span>
<span></span>
<span>    <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='nv'>polygons_in_batch</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>      <span class='nf'><a href='https://rdrr.io/r/base/cbind.html'>cbind</a></span><span class='o'>(</span><span class='nv'>coords_in_batch</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>      <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span></span>
<span>        origin <span class='o'>=</span> <span class='nf'>dm_origin_address</span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span>,</span>
<span>        commute_distance_m <span class='o'>=</span> <span class='nf'>dm_distance</span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span>,</span>
<span>        commute_time_s <span class='o'>=</span> <span class='nf'>dm_time</span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span>,</span>
<span>        commute_time <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='o'>(</span><span class='nv'>commute_time_s</span> <span class='o'>/</span> <span class='m'>60</span>, <span class='m'>1</span><span class='o'>)</span>, <span class='s'>"minutes"</span><span class='o'>)</span></span>
<span>      <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>      <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='o'>)</span></span>
<span>  <span class='o'>&#125;</span></span>
<span></span>
<span>  <span class='nf'>purrr</span><span class='nf'>::</span><span class='nf'><a href='https://purrr.tidyverse.org/reference/map_dfr.html'>map_dfr</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/seq.html'>seq</a></span><span class='o'>(</span><span class='nv'>batches</span><span class='o'>)</span>, <span class='nv'>query_batch_number</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/distinct.html'>distinct</a></span><span class='o'>(</span><span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

And here is the function in action for Brunswick:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>grid_in_brunswick</span> <span class='o'>&lt;-</span> <span class='nf'>suburb_grid</span><span class='o'>(</span><span class='nv'>metro_grid</span>, <span class='nv'>localities</span>, <span class='s'>"Brunswick"</span><span class='o'>)</span></span>
<span><span class='nv'>brunswick_commute_facts</span> <span class='o'>&lt;-</span> <span class='nf'>commute_facts</span><span class='o'>(</span><span class='nv'>grid_in_brunswick</span><span class='o'>)</span></span>
<span><span class='nv'>brunswick_commute_facts</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'># A tibble: 121 × 7</span></span></span>
<span><span class='c'>#&gt;                              geometry     X     Y origin commu…¹ commu…² commu…³</span></span>
<span><span class='c'>#&gt;                         <span style='color: #555555; font-style: italic;'>&lt;POLYGON [°]&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>    <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span>   <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>  </span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 1</span> ((144.9478 -37.77175, 144.9466 -3…  145. -<span style='color: #BB0000;'>37.8</span> 5 Fod…    <span style='text-decoration: underline;'>4</span>629    <span style='text-decoration: underline;'>1</span>459 24.3 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 2</span> ((144.9491 -37.77825, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> Park …    <span style='text-decoration: underline;'>3</span>651    <span style='text-decoration: underline;'>1</span>110 18.5 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 3</span> ((144.9491 -37.77392, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 14/19…    <span style='text-decoration: underline;'>4</span>221    <span style='text-decoration: underline;'>1</span>247 20.8 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 4</span> ((144.9491 -37.76959, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 30 Pe…    <span style='text-decoration: underline;'>4</span>733    <span style='text-decoration: underline;'>1</span>518 25.3 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 5</span> ((144.9491 -37.76526, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 95A P…    <span style='text-decoration: underline;'>5</span>557    <span style='text-decoration: underline;'>1</span>856 30.9 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 6</span> ((144.9491 -37.76093, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 28 Ha…    <span style='text-decoration: underline;'>6</span>528    <span style='text-decoration: underline;'>2</span>003 33.4 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 7</span> ((144.9503 -37.77608, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> 26 He…    <span style='text-decoration: underline;'>4</span>007    <span style='text-decoration: underline;'>1</span>304 21.7 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 8</span> ((144.9503 -37.77175, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> Grant…    <span style='text-decoration: underline;'>4</span>501    <span style='text-decoration: underline;'>1</span>326 22.1 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 9</span> ((144.9503 -37.76742, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> 460 V…    <span style='text-decoration: underline;'>5</span>394    <span style='text-decoration: underline;'>1</span>745 29.1 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'>10</span> ((144.9503 -37.76309, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> 118 P…    <span style='text-decoration: underline;'>5</span>917    <span style='text-decoration: underline;'>2</span>124 35.4 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'># … with 111 more rows, and abbreviated variable names ¹​commute_distance_m,</span></span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'>#   ²​commute_time_s, ³​commute_time</span></span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'># ℹ Use `print(n = ...)` to see more rows</span></span></span>
<span></span></code></pre>

</div>

## Avoiding repetition

If I try to calculate commute times for two adjacent suburbs, I'm going to have some overlap at the boundaries. API calls are expensive so it's worth making sure I don't query the same hexagon twice. The below function takes an existing data frame of commutes (like `brunswick_commute_facts` above) and adds commute facts from another suburb, being sure not to query data for any polygon I already know about.

I'm not proud of my method for detecting overlaps here. I resort to several lines of `dplyr` but it feels like there must be an easier way,

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>expand_commute_facts</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>polygons</span>, <span class='nv'>existing</span> <span class='o'>=</span> <span class='kc'>NULL</span>, <span class='nv'>destination</span> <span class='o'>=</span> <span class='nv'>workplace</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='o'>(</span><span class='nv'>existing</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='nf'>commute_facts</span><span class='o'>(</span><span class='nv'>polygons</span>, destination <span class='o'>=</span> <span class='nv'>destination</span><span class='o'>)</span><span class='o'>)</span></span>
<span>  <span class='o'>&#125;</span></span>
<span></span>
<span>  <span class='nv'>polygon_df</span> <span class='o'>&lt;-</span> <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='nf'>polygon_centroids</span><span class='o'>(</span><span class='nv'>polygons</span><span class='o'>)</span><span class='o'>)</span></span>
<span>  <span class='nv'>existing_df</span> <span class='o'>&lt;-</span> <span class='nv'>existing</span><span class='o'>[</span><span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"X"</span>, <span class='s'>"Y"</span><span class='o'>)</span><span class='o'>]</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span> <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>exists <span class='o'>=</span> <span class='kc'>TRUE</span><span class='o'>)</span></span>
<span>  <span class='nv'>existing_index</span> <span class='o'>&lt;-</span> <span class='nv'>polygon_df</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate-joins.html'>left_join</a></span><span class='o'>(</span><span class='nv'>existing_df</span>, by <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"X"</span>, <span class='s'>"Y"</span><span class='o'>)</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate.html'>mutate</a></span><span class='o'>(</span>exists <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='o'>(</span><span class='nv'>exists</span><span class='o'>)</span>, <span class='kc'>FALSE</span>, <span class='nv'>exists</span><span class='o'>)</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/pull.html'>pull</a></span><span class='o'>(</span><span class='nv'>exists</span><span class='o'>)</span></span>
<span>  <span class='nv'>new_polygons</span> <span class='o'>&lt;-</span> <span class='nv'>polygons</span><span class='o'>[</span><span class='o'>!</span><span class='nv'>existing_index</span><span class='o'>]</span></span>
<span></span>
<span>  <span class='nf'><a href='https://rdrr.io/r/base/cbind.html'>rbind</a></span><span class='o'>(</span></span>
<span>    <span class='nv'>existing</span>,</span>
<span>    <span class='nf'>commute_facts</span><span class='o'>(</span><span class='nv'>new_polygons</span>, destination <span class='o'>=</span> <span class='nv'>destination</span><span class='o'>)</span></span>
<span>  <span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

I would then be able to add new commute facts like so:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>fitzroy_and_brunswick_commute_facts</span> <span class='o'>&lt;-</span> <span class='nf'>expand_commute_facts</span><span class='o'>(</span></span>
<span>    <span class='nf'>suburb_grid</span><span class='o'>(</span><span class='nv'>metro_grid</span>, <span class='nv'>localities</span>, <span class='s'>"Fitzroy"</span><span class='o'>)</span>,</span>
<span>    existing <span class='o'>=</span> <span class='nv'>brunswick_commute_facts</span></span>
<span><span class='o'>)</span></span>
<span><span class='nv'>fitzroy_and_brunswick_commute_facts</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'># A tibble: 162 × 7</span></span></span>
<span><span class='c'>#&gt;                              geometry     X     Y origin commu…¹ commu…² commu…³</span></span>
<span><span class='c'>#&gt;                         <span style='color: #555555; font-style: italic;'>&lt;POLYGON [°]&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;dbl&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>    <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span>   <span style='color: #555555; font-style: italic;'>&lt;int&gt;</span> <span style='color: #555555; font-style: italic;'>&lt;chr&gt;</span>  </span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 1</span> ((144.9478 -37.77175, 144.9466 -3…  145. -<span style='color: #BB0000;'>37.8</span> 5 Fod…    <span style='text-decoration: underline;'>4</span>629    <span style='text-decoration: underline;'>1</span>459 24.3 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 2</span> ((144.9491 -37.77825, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> Park …    <span style='text-decoration: underline;'>3</span>651    <span style='text-decoration: underline;'>1</span>110 18.5 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 3</span> ((144.9491 -37.77392, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 14/19…    <span style='text-decoration: underline;'>4</span>221    <span style='text-decoration: underline;'>1</span>247 20.8 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 4</span> ((144.9491 -37.76959, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 30 Pe…    <span style='text-decoration: underline;'>4</span>733    <span style='text-decoration: underline;'>1</span>518 25.3 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 5</span> ((144.9491 -37.76526, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 95A P…    <span style='text-decoration: underline;'>5</span>557    <span style='text-decoration: underline;'>1</span>856 30.9 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 6</span> ((144.9491 -37.76093, 144.9478 -3…  145. -<span style='color: #BB0000;'>37.8</span> 28 Ha…    <span style='text-decoration: underline;'>6</span>528    <span style='text-decoration: underline;'>2</span>003 33.4 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 7</span> ((144.9503 -37.77608, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> 26 He…    <span style='text-decoration: underline;'>4</span>007    <span style='text-decoration: underline;'>1</span>304 21.7 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 8</span> ((144.9503 -37.77175, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> Grant…    <span style='text-decoration: underline;'>4</span>501    <span style='text-decoration: underline;'>1</span>326 22.1 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> 9</span> ((144.9503 -37.76742, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> 460 V…    <span style='text-decoration: underline;'>5</span>394    <span style='text-decoration: underline;'>1</span>745 29.1 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'>10</span> ((144.9503 -37.76309, 144.9491 -3…  145. -<span style='color: #BB0000;'>37.8</span> 118 P…    <span style='text-decoration: underline;'>5</span>917    <span style='text-decoration: underline;'>2</span>124 35.4 m…</span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'># … with 152 more rows, and abbreviated variable names ¹​commute_distance_m,</span></span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'>#   ²​commute_time_s, ³​commute_time</span></span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'># ℹ Use `print(n = ...)` to see more rows</span></span></span>
<span></span></code></pre>

</div>

## Map colours

Before I get to visualising the hexagons I want to define the colour legend. Everyone has different tolerances for commuting, but in my case I decided to set everything above 1 hour as the same colour as that used for 1 hour. I also set everything below 20 minutes as the same colour as that used for 20 minutes. This means that --- for the purpose of the colour scale --- I need to "clamp" my commute times to between 20 and 60 minutes. That is, values below 20 minutes will be raised to 20 and values above 60 minutes will be lowered to 60. These limits will be passed to my plotting function as `min_value` and `max_value` arguments.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='c'># I wish this function was in base R</span></span>
<span><span class='nv'>clamp_values</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>values</span>, <span class='nv'>min_value</span> <span class='o'>=</span> <span class='kc'>NULL</span>, <span class='nv'>max_value</span> <span class='o'>=</span> <span class='kc'>NULL</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='o'>(</span><span class='nv'>min_value</span><span class='o'>)</span><span class='o'>)</span> <span class='nv'>min_value</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/Extremes.html'>min</a></span><span class='o'>(</span><span class='nv'>values</span>, na.rm <span class='o'>=</span> <span class='kc'>TRUE</span><span class='o'>)</span></span>
<span>  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='o'>(</span><span class='nv'>max_value</span><span class='o'>)</span><span class='o'>)</span> <span class='nv'>max_value</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/Extremes.html'>max</a></span><span class='o'>(</span><span class='nv'>values</span>, na.rm <span class='o'>=</span> <span class='kc'>TRUE</span><span class='o'>)</span></span>
<span></span>
<span>  <span class='nv'>clamped_values</span> <span class='o'>&lt;-</span> <span class='nv'>values</span></span>
<span>  <span class='nv'>clamped_values</span><span class='o'>[</span><span class='nv'>values</span> <span class='o'>&gt;</span> <span class='nv'>max_value</span><span class='o'>]</span> <span class='o'>&lt;-</span> <span class='nv'>max_value</span></span>
<span>  <span class='nv'>clamped_values</span><span class='o'>[</span><span class='nv'>values</span> <span class='o'>&lt;</span> <span class='nv'>min_value</span><span class='o'>]</span> <span class='o'>&lt;-</span> <span class='nv'>min_value</span></span>
<span></span>
<span>  <span class='nv'>clamped_values</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

I can then define my colours using `leaflet`'s colour palette functions. I have the option of reversing the palette, which I default to `TRUE` because I have the "spectral" palette in mind. Without reversing, red would represent lower values and blue would represent higher values, which defies convention.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>clamped_palette_function</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>palette</span>, <span class='nv'>values</span>, <span class='nv'>min_value</span> <span class='o'>=</span> <span class='kc'>NULL</span>, <span class='nv'>max_value</span> <span class='o'>=</span> <span class='kc'>NULL</span>, <span class='nv'>reverse_palette</span> <span class='o'>=</span> <span class='kc'>TRUE</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>clamped_values</span> <span class='o'>&lt;-</span> <span class='nf'>clamp_values</span><span class='o'>(</span><span class='nv'>values</span>, <span class='nv'>min_value</span>, <span class='nv'>max_value</span><span class='o'>)</span></span>
<span></span>
<span>  <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/colorNumeric.html'>colorNumeric</a></span><span class='o'>(</span></span>
<span>    <span class='nv'>palette</span>,</span>
<span>    reverse <span class='o'>=</span> <span class='nv'>reverse_palette</span>,</span>
<span>    domain <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/Extremes.html'>min</a></span><span class='o'>(</span><span class='nv'>clamped_values</span><span class='o'>)</span><span class='o'>:</span><span class='nf'><a href='https://rdrr.io/r/base/Extremes.html'>max</a></span><span class='o'>(</span><span class='nv'>clamped_values</span><span class='o'>)</span></span>
<span>  <span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

## Map title

Leaflet doesn't support titles out of the box (at least not through the R package, as far as I know). I adapted this solution from [StackOverflow](https://stackoverflow.com/a/72058737/8456369). It requires the creation of a CSS class for the title which can then be added to the Leaflet plot.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>leaflet_title_class</span> <span class='o'>&lt;-</span> <span class='nf'>htmltools</span><span class='nf'>::</span><span class='nv'><a href='https://rstudio.github.io/htmltools/reference/builder.html'>tags</a></span><span class='o'>$</span><span class='nf'>style</span><span class='o'>(</span><span class='nf'>htmltools</span><span class='nf'>::</span><span class='nf'><a href='https://rstudio.github.io/htmltools/reference/HTML.html'>HTML</a></span><span class='o'>(</span><span class='s'>"</span></span>
<span><span class='s'>  .leaflet-control.map-title &#123;</span></span>
<span><span class='s'>    transform: translate(-50%,20%);</span></span>
<span><span class='s'>    position: fixed !important;</span></span>
<span><span class='s'>    left: 38%;</span></span>
<span><span class='s'>    max-width: 50%;</span></span>
<span><span class='s'>    text-align: center;</span></span>
<span><span class='s'>    padding-left: 5px;</span></span>
<span><span class='s'>    padding-right: 5px;</span></span>
<span><span class='s'>    background: rgba(255,255,255,0.75);</span></span>
<span><span class='s'>    font-weight: bold;</span></span>
<span><span class='s'>    font-size: 1.0em;</span></span>
<span><span class='s'>  &#125;</span></span>
<span><span class='s'>"</span><span class='o'>)</span><span class='o'>)</span></span>
<span></span>
<span><span class='nv'>leaflet_title</span> <span class='o'>&lt;-</span> <span class='nf'>htmltools</span><span class='nf'>::</span><span class='nv'><a href='https://rstudio.github.io/htmltools/reference/builder.html'>tags</a></span><span class='o'>$</span><span class='nf'>div</span><span class='o'>(</span></span>
<span>  <span class='nv'>leaflet_title_class</span>,</span>
<span>  <span class='nf'>htmltools</span><span class='nf'>::</span><span class='nf'><a href='https://rstudio.github.io/htmltools/reference/HTML.html'>HTML</a></span><span class='o'>(</span><span class='s'>"Public transport commute time to University of Melbourne&lt;br&gt;by David Neuzerling"</span><span class='o'>)</span></span>
<span><span class='o'>)</span></span></code></pre>

</div>

## Leaflet plot

With all of the pieces in place I can now define my `plot_commutes` function. The layers are built up:

1.  I first create the empty plot and add the title
2.  I add the actual map of Melbourne from OpenStreetMap
3.  I centre the map on the commute destination and set the zoom level
4.  I add the hexagon plot with the colour scale I defined earlier. By setting `weight = 0` I can remove the borders around each hexagon so that the colours blend a little. The labels will show the actual commute time when the user hovers over a hexagon (if on desktop) or taps on a hexagon (if on mobile).
5.  I add the legend, formatting the commute time (which is in seconds) as minutes

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>plot_commutes</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span></span>
<span>    <span class='nv'>polygons</span>,</span>
<span>    <span class='nv'>colour_by</span>,</span>
<span>    <span class='nv'>destination</span> <span class='o'>=</span> <span class='nv'>workplace</span>,</span>
<span>    <span class='nv'>min_value</span> <span class='o'>=</span> <span class='m'>20</span> <span class='o'>*</span> <span class='m'>60</span>,</span>
<span>    <span class='nv'>max_value</span> <span class='o'>=</span> <span class='m'>60</span> <span class='o'>*</span> <span class='m'>60</span></span>
<span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>non_na_polygons</span> <span class='o'>&lt;-</span> <span class='nf'>dplyr</span><span class='nf'>::</span><span class='nf'><a href='https://dplyr.tidyverse.org/reference/filter.html'>filter</a></span><span class='o'>(</span><span class='nv'>polygons</span>, <span class='o'>!</span><span class='nf'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='o'>(</span><span class='nv'>commute_time_s</span><span class='o'>)</span><span class='o'>)</span></span>
<span></span>
<span>  <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/leaflet.html'>leaflet</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/map-layers.html'>addControl</a></span><span class='o'>(</span><span class='nv'>leaflet_title</span>, position <span class='o'>=</span> <span class='s'>"topleft"</span>, className <span class='o'>=</span> <span class='s'>"map-title"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/addProviderTiles.html'>addProviderTiles</a></span><span class='o'>(</span><span class='s'>"OpenStreetMap"</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/map-methods.html'>setView</a></span><span class='o'>(</span>lng <span class='o'>=</span> <span class='nv'>destination</span><span class='o'>[</span><span class='m'>1</span><span class='o'>]</span>, lat <span class='o'>=</span> <span class='nv'>destination</span><span class='o'>[</span><span class='m'>2</span><span class='o'>]</span>, zoom <span class='o'>=</span> <span class='m'>11</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/map-layers.html'>addPolygons</a></span><span class='o'>(</span></span>
<span>      data <span class='o'>=</span> <span class='nf'>sf</span><span class='nf'>::</span><span class='nf'><a href='https://r-spatial.github.io/sf/reference/st_transform.html'>st_transform</a></span><span class='o'>(</span><span class='nv'>non_na_polygons</span><span class='o'>$</span><span class='nv'>geometry</span>, <span class='s'>"+proj=longlat +datum=WGS84"</span><span class='o'>)</span>,</span>
<span>      fillColor <span class='o'>=</span> <span class='nf'>clamped_palette</span><span class='o'>(</span></span>
<span>        <span class='s'>"Spectral"</span>,</span>
<span>        <span class='nv'>non_na_polygons</span><span class='o'>$</span><span class='nv'>commute_time_s</span>,</span>
<span>        min_value <span class='o'>=</span> <span class='nv'>min_value</span>,</span>
<span>        max_value <span class='o'>=</span> <span class='nv'>max_value</span></span>
<span>      <span class='o'>)</span>,</span>
<span>      fillOpacity <span class='o'>=</span> <span class='m'>0.4</span>,</span>
<span>      weight <span class='o'>=</span> <span class='m'>0</span>,</span>
<span>      label <span class='o'>=</span> <span class='nv'>non_na_polygons</span><span class='o'>$</span><span class='nv'>commute_time</span></span>
<span>    <span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/addLegend.html'>addLegend</a></span><span class='o'>(</span></span>
<span>      title <span class='o'>=</span> <span class='s'>"commute time"</span>,</span>
<span>      pal <span class='o'>=</span> <span class='nf'>clamped_palette_function</span><span class='o'>(</span></span>
<span>        <span class='s'>"Spectral"</span>,</span>
<span>        <span class='nv'>non_na_polygons</span><span class='o'>$</span><span class='nv'>commute_time_s</span>,</span>
<span>        min_value <span class='o'>=</span> <span class='nv'>min_value</span>,</span>
<span>        max_value <span class='o'>=</span> <span class='nv'>max_value</span></span>
<span>      <span class='o'>)</span>,</span>
<span>      values <span class='o'>=</span> <span class='nf'>clamp_values</span><span class='o'>(</span><span class='nv'>non_na_polygons</span><span class='o'>$</span><span class='nv'>commute_time_s</span>, <span class='nv'>min_value</span>, <span class='nv'>max_value</span><span class='o'>)</span>,</span>
<span>      labFormat <span class='o'>=</span> <span class='nf'>leaflet</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/leaflet/man/addLegend.html'>labelFormat</a></span><span class='o'>(</span></span>
<span>        suffix <span class='o'>=</span> <span class='s'>" min"</span>,</span>
<span>        transform <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='nf'><a href='https://rdrr.io/r/base/Round.html'>round</a></span><span class='o'>(</span><span class='nv'>x</span> <span class='o'>/</span> <span class='m'>60</span><span class='o'>)</span></span>
<span>      <span class='o'>)</span></span>
<span>    <span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

## Saving the widget

I use the `htmlwidgets` package to export the `leaflet` plot as a HTML site. Before doing so I need to define the "viewport" that allows mobile devices to properly display the map. Without this they would attempt to render the plot as if viewing on a desktop computer which would make the text far too small to read.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nv'>viewport</span> <span class='o'>&lt;-</span> <span class='nf'>htmltools</span><span class='nf'>::</span><span class='nv'><a href='https://rstudio.github.io/htmltools/reference/builder.html'>tags</a></span><span class='o'>$</span><span class='nf'>meta</span><span class='o'>(</span></span>
<span>  name <span class='o'>=</span> <span class='s'>"viewport"</span>,</span>
<span>  content <span class='o'>=</span> <span class='s'>"width=device-width, initial-scale=1.0"</span></span>
<span><span class='o'>)</span></span>
<span></span>
<span><span class='nv'>save_commute_plot</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>commute_plot</span>, <span class='nv'>file_path</span><span class='o'>)</span> <span class='o'>&#123;</span></span>
<span>  <span class='nv'>commute_plot</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>htmlwidgets</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/htmlwidgets/man/prependContent.html'>prependContent</a></span><span class='o'>(</span><span class='nv'>viewport</span><span class='o'>)</span> <span class='o'><a href='https://magrittr.tidyverse.org/reference/pipe.html'>%&gt;%</a></span></span>
<span>    <span class='nf'>htmlwidgets</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html'>saveWidget</a></span><span class='o'>(</span><span class='nv'>file_path</span><span class='o'>)</span></span>
<span><span class='o'>&#125;</span></span></code></pre>

</div>

The resulting directory can be uploaded to any web server or static site hosting service, such as [Netlify](https://app.netlify.com).

------------------------------------------------------------------------

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span><span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://r-lib.github.io/sessioninfo/reference/session_info.html'>session_info</a></span><span class='o'>(</span><span class='o'>)</span></span>
<span><span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>─ Session info ───────────────────────────────────────────────────────────────</span></span></span>
<span><span class='c'>#&gt;  <span style='color: #555555; font-style: italic;'>setting </span> <span style='color: #555555; font-style: italic;'>value</span></span></span>
<span><span class='c'>#&gt;  version  R version 4.2.1 (2022-06-23)</span></span>
<span><span class='c'>#&gt;  os       macOS Big Sur 11.3</span></span>
<span><span class='c'>#&gt;  system   aarch64, darwin20</span></span>
<span><span class='c'>#&gt;  ui       X11</span></span>
<span><span class='c'>#&gt;  language (EN)</span></span>
<span><span class='c'>#&gt;  collate  en_AU.UTF-8</span></span>
<span><span class='c'>#&gt;  ctype    en_AU.UTF-8</span></span>
<span><span class='c'>#&gt;  tz       Australia/Melbourne</span></span>
<span><span class='c'>#&gt;  date     2023-02-12</span></span>
<span><span class='c'>#&gt;  pandoc   2.18 @ /Applications/RStudio.app/Contents/MacOS/quarto/bin/tools/ (via rmarkdown)</span></span>
<span><span class='c'>#&gt; </span></span>
<span><span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>─ Packages ───────────────────────────────────────────────────────────────────</span></span></span>
<span><span class='c'>#&gt;  <span style='color: #555555; font-style: italic;'>package    </span> <span style='color: #555555; font-style: italic;'>*</span> <span style='color: #555555; font-style: italic;'>version   </span> <span style='color: #555555; font-style: italic;'>date (UTC)</span> <span style='color: #555555; font-style: italic;'>lib</span> <span style='color: #555555; font-style: italic;'>source</span></span></span>
<span><span class='c'>#&gt;  assertthat    0.2.1      <span style='color: #555555;'>2019-03-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  cachem        1.0.6      <span style='color: #555555;'>2021-08-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  callr         3.7.1      <span style='color: #555555;'>2022-07-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  class         7.3-20     <span style='color: #555555;'>2022-01-16</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.1)</span></span></span>
<span><span class='c'>#&gt;  classInt      0.4-7      <span style='color: #555555;'>2022-06-10</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  cli           3.6.0      <span style='color: #555555;'>2023-01-09</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  crayon        1.5.2      <span style='color: #555555;'>2022-09-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  crosstalk     1.2.0      <span style='color: #555555;'>2021-11-04</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  curl          5.0.0      <span style='color: #555555;'>2023-01-12</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  DBI           1.1.3      <span style='color: #555555;'>2022-06-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  devtools      2.4.4      <span style='color: #555555;'>2022-07-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  digest        0.6.31     <span style='color: #555555;'>2022-12-11</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  downlit       0.4.2      <span style='color: #555555;'>2022-07-05</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  dplyr       * 1.0.9      <span style='color: #555555;'>2022-04-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  e1071         1.7-11     <span style='color: #555555;'>2022-06-07</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  ellipsis      0.3.2      <span style='color: #555555;'>2021-04-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  evaluate      0.20       <span style='color: #555555;'>2023-01-17</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  fansi         1.0.4      <span style='color: #555555;'>2023-01-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  fastmap       1.1.0      <span style='color: #555555;'>2021-01-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  fs            1.6.0      <span style='color: #555555;'>2023-01-23</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  generics      0.1.3      <span style='color: #555555;'>2022-07-05</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  glue          1.6.2      <span style='color: #555555;'>2022-02-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  googleway     2.7.6      <span style='color: #555555;'>2022-01-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  highr         0.10       <span style='color: #555555;'>2022-12-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  htmltools     0.5.4      <span style='color: #555555;'>2022-12-07</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  htmlwidgets   1.5.4      <span style='color: #555555;'>2021-09-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  httpuv        1.6.5      <span style='color: #555555;'>2022-01-05</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  hugodown      <span style='color: #BB00BB; font-weight: bold;'>0.0.0.9000</span> <span style='color: #555555;'>2023-01-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #BB00BB; font-weight: bold;'>Github (r-lib/hugodown@f6f23dd)</span></span></span>
<span><span class='c'>#&gt;  jsonlite      1.8.4      <span style='color: #555555;'>2022-12-06</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  KernSmooth    2.23-20    <span style='color: #555555;'>2021-05-03</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.1)</span></span></span>
<span><span class='c'>#&gt;  knitr         1.42       <span style='color: #555555;'>2023-01-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  later         1.3.0      <span style='color: #555555;'>2021-08-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  leaflet       2.1.1      <span style='color: #555555;'>2022-03-23</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  lifecycle     1.0.3      <span style='color: #555555;'>2022-10-07</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  magrittr      2.0.3      <span style='color: #555555;'>2022-03-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  memoise       2.0.1      <span style='color: #555555;'>2021-11-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  mime          0.12       <span style='color: #555555;'>2021-09-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  miniUI        0.1.1.1    <span style='color: #555555;'>2018-05-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  pillar        1.8.0      <span style='color: #555555;'>2022-07-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.1)</span></span></span>
<span><span class='c'>#&gt;  pkgbuild      1.3.1      <span style='color: #555555;'>2021-12-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  pkgconfig     2.0.3      <span style='color: #555555;'>2019-09-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  pkgload       1.3.0      <span style='color: #555555;'>2022-06-27</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  prettyunits   1.1.1      <span style='color: #555555;'>2020-01-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  processx      3.8.0      <span style='color: #555555;'>2022-10-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  profvis       0.3.7      <span style='color: #555555;'>2020-11-02</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  promises      1.2.0.1    <span style='color: #555555;'>2021-02-11</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  proxy         0.4-27     <span style='color: #555555;'>2022-06-09</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  ps            1.7.2      <span style='color: #555555;'>2022-10-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  purrr         1.0.1      <span style='color: #555555;'>2023-01-10</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  R6            2.5.1      <span style='color: #555555;'>2021-08-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  Rcpp          1.0.10     <span style='color: #555555;'>2023-01-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  remotes       2.4.2      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  rlang         1.0.6      <span style='color: #555555;'>2022-09-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  rmarkdown     2.20       <span style='color: #555555;'>2023-01-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  rstudioapi    0.14       <span style='color: #555555;'>2022-08-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  s2            1.1.0      <span style='color: #555555;'>2022-07-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  sessioninfo   1.2.2      <span style='color: #555555;'>2021-12-06</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  sf            1.0-9      <span style='color: #555555;'>2022-11-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  shiny         1.7.2      <span style='color: #555555;'>2022-07-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  stringi       1.7.12     <span style='color: #555555;'>2023-01-11</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  stringr       1.5.0      <span style='color: #555555;'>2022-12-02</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  tibble        3.1.8      <span style='color: #555555;'>2022-07-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  tidyselect    1.1.2      <span style='color: #555555;'>2022-02-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  units         0.8-0      <span style='color: #555555;'>2022-02-05</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  urlchecker    1.0.1      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  usethis       2.1.6      <span style='color: #555555;'>2022-05-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  utf8          1.2.2      <span style='color: #555555;'>2021-07-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  vctrs         0.5.2      <span style='color: #555555;'>2023-01-23</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  withr         2.5.0      <span style='color: #555555;'>2022-03-03</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  wk            0.6.0      <span style='color: #555555;'>2022-01-03</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  xfun          0.36       <span style='color: #555555;'>2022-12-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  xtable        1.8-4      <span style='color: #555555;'>2019-04-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt;  yaml          2.3.7      <span style='color: #555555;'>2023-01-23</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.2.0)</span></span></span>
<span><span class='c'>#&gt; </span></span>
<span><span class='c'>#&gt; <span style='color: #555555;'> [1] /Library/Frameworks/R.framework/Versions/4.2-arm64/Resources/library</span></span></span>
<span><span class='c'>#&gt; </span></span>
<span><span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>──────────────────────────────────────────────────────────────────────────────</span></span></span>
<span></span></code></pre>

</div>

