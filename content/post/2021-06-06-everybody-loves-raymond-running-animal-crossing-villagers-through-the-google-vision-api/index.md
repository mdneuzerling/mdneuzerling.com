---
title: "Everybody Loves Raymond: Running Animal Crossing Villagers through the Google Vision API"
author: ~
date: '2021-06-06'
slug: everybody-loves-raymond-running-animal-crossing-villagers-through-the-google-vision-api
category: code
tags:
    - R
    - cloud
featured: "/img/featured/animal-crossing.webp"
output: hugodown::md_document
rmd_hash: a5e4cb308efac501

---

*Animal Crossing: New Horizons* kept me sane throughout the first Melbourne COVID lockdown. Now, in lockdown 4, it seems right that I should look back at this cheerful, relaxing game and do some data stuff. I'm going to take the *Animal Crossing* villagers in the [Tidy Tuesday Animal Crossing dataset](https://github.com/rfordatascience/tidytuesday/blob/master/data/2020/2020-05-05/readme.md) and combine it with survey data from the [Animal Crossing Portal](https://www.animalcrossingportal.com/games/new-horizons/guides/villager-popularity-list.php#/), giving each villager a measure of popularity. I'll use the [Google Cloud Vision API](https://cloud.google.com/vision) to annotate each of the villager thumbnails, and with these train a a (pretty poor) model of villager popularity.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://tidyverse.tidyverse.org'>tidyverse</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://tidymodels.tidymodels.org'>tidymodels</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://github.com/tidyverse/glue'>glue</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://httr.r-lib.org/'>httr</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://github.com/GuangchuangYu/ggimage'>ggimage</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://patchwork.data-imaginist.com'>patchwork</a></span><span class='o'>)</span>
<span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://lime.data-imaginist.com'>lime</a></span><span class='o'>)</span></code></pre>

</div>

## Retrieve the villager popularity votes

The [Animal Crossing Portal](https://www.animalcrossingportal.com/) is a fan site that runs a monthly poll on favourite villagers. They keep historical data in publicly available Google Sheets, which makes a data scientist like me very happy.

The sheet is a list of votes, but two columns to the side tally the total votes for each villager. That leaves a lot of dangling empty rows. I'll grab those two columns and delete the empty rows.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>popularity_url</span> <span class='o'>&lt;-</span> <span class='s'>"https://docs.google.com/spreadsheets/d/1ADak5KpVYjeSRNN4qudYERMotPkeRP5n4rN_VpOQm4Y/edit#gid=0"</span>
<span class='nf'>googlesheets4</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/googlesheets4/man/gs4_deauth.html'>gs4_deauth</a></span><span class='o'>(</span><span class='o'>)</span> <span class='c'># disable authentication for this public sheet</span>

<span class='nv'>popularity</span> <span class='o'>&lt;-</span> <span class='nf'>googlesheets4</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/googlesheets4/man/range_read.html'>read_sheet</a></span><span class='o'>(</span><span class='nv'>popularity_url</span><span class='o'>)</span> <span class='o'>%&gt;%</span>
    <span class='nf'>transmute</span><span class='o'>(</span> <span class='c'># transmute combines mutate and select</span>
        name <span class='o'>=</span> <span class='nv'>Villagers</span>,
        popularity <span class='o'>=</span> <span class='nv'>Tally</span>
    <span class='o'>)</span> <span class='o'>%&gt;%</span>
    <span class='nf'><a href='https://rdrr.io/r/stats/na.fail.html'>na.omit</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; Reading from "April 2021 Poll Final Vote Count"</span>
<span class='c'>#&gt; Range "Sheet1"</span>
<span class='c'>#&gt; New names:</span>
<span class='c'>#&gt; * `` -&gt; ...7</span>
<span class='c'>#&gt; * `` -&gt; ...10</span>

<span class='nv'>popularity</span> <span class='o'>%&gt;%</span> <span class='nf'>arrange</span><span class='o'>(</span><span class='o'>-</span><span class='nv'>popularity</span><span class='o'>)</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 6 x 2</span></span>
<span class='c'>#&gt;   name    popularity</span>
<span class='c'>#&gt;   <span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>        </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>1</span><span> Marshal        725</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>2</span><span> Raymond        656</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>3</span><span> Sherb          579</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>4</span><span> Zucker         558</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>5</span><span> Judy           421</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>6</span><span> Fauna          407</span></span></code></pre>

</div>

## Retrieve the Tidy Tuesday villager data

I always come late to the Tidy Tuesday party. This is the dataset from 2020-05-05. It contains a data frame of every villager available in *Animal Crossing: New Horizons* (at the time), with their gender, species, and a few other attributes. It also contains a `url` column pointing to a thumbnail of the villager --- I'll use this later when I'm querying the Vision API.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>tidy_tuesday_data</span> <span class='o'>&lt;-</span> <span class='nf'>tidytuesdayR</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/tidytuesdayR/man/tt_load.html'>tt_load</a></span><span class='o'>(</span><span class='s'>"2020-05-05"</span><span class='o'>)</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt;   Downloading file 1 of 4: `critic.tsv`</span>
<span class='c'>#&gt;   Downloading file 2 of 4: `items.csv`</span>
<span class='c'>#&gt;   Downloading file 3 of 4: `user_reviews.tsv`</span>
<span class='c'>#&gt;   Downloading file 4 of 4: `villagers.csv`</span>
<span class='nv'>tidy_tuesday_villagers</span> <span class='o'>&lt;-</span> <span class='nv'>tidy_tuesday_data</span><span class='o'>$</span><span class='nv'>villagers</span>
<span class='nv'>tidy_tuesday_villagers</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 6 x 11</span></span>
<span class='c'>#&gt;   row_n id     name   gender species birthday personality song   phrase full_id </span>
<span class='c'>#&gt;   <span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>   </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>    </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>       </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>   </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>1</span><span>     2 admir… Admir… male   bird    1-27     cranky      Steep… aye a… village…</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>2</span><span>     3 agent… Agent… female squirr… 7-2      peppy       DJ K.… sidek… village…</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>3</span><span>     4 agnes  Agnes  female pig     4-21     uchi        K.K. … snuff… village…</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>4</span><span>     6 al     Al     male   gorilla 10-18    lazy        Steep… Ayyee… village…</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>5</span><span>     7 alfon… Alfon… male   alliga… 6-9      lazy        Fores… it'sa… village…</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>6</span><span>     8 alice  Alice  female koala   8-19     normal      Surfi… guvnor village…</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 1 more variable: url &lt;chr&gt;</span></span></code></pre>

</div>

Running assertions against datasets is a good idea. I'll check that I have a popularity score for every villager. There are villagers in the `popularity` data that aren't in the Tidy Tuesday data, but this is to be expected as new characters have been released in the time since the Tidy Tuesday data set was published. I'll also check that there are no missing values in columns that I care about --- there are missing values for the villagers' favourite songs, but I don't need that information.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>tidy_tuesday_villagers</span> <span class='o'>%&gt;%</span>
  <span class='nf'>anti_join</span><span class='o'>(</span><span class='nv'>popularity</span>, by <span class='o'>=</span> <span class='s'>"name"</span><span class='o'>)</span> <span class='o'>%&gt;%</span>   
  <span class='o'>&#123;</span><span class='nf'>assertthat</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/assertthat/man/assert_that.html'>assert_that</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='o'>(</span><span class='nv'>.</span><span class='o'>)</span> <span class='o'>==</span> <span class='m'>0</span><span class='o'>)</span><span class='o'>&#125;</span>
<span class='c'>#&gt; [1] TRUE</span>
<span class='nv'>tidy_tuesday_villagers</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>select</span><span class='o'>(</span><span class='o'>-</span><span class='nv'>song</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/r/stats/complete.cases.html'>complete.cases</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/r/base/all.html'>all</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>assertthat</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/assertthat/man/assert_that.html'>assert_that</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; [1] TRUE</span></code></pre>

</div>

With those checks done, I can safely join:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>villagers</span> <span class='o'>&lt;-</span> <span class='nv'>tidy_tuesday_villagers</span> <span class='o'>%&gt;%</span> <span class='nf'>left_join</span><span class='o'>(</span><span class='nv'>popularity</span>, by <span class='o'>=</span> <span class='s'>"name"</span><span class='o'>)</span></code></pre>

</div>

## This data is fun to plot

Those thumbnails add a bit of flair to any plot. It should come as no surprise to any *Animal Crossing* fan that Marshal is the favourite:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>villagers</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>arrange</span><span class='o'>(</span><span class='o'>-</span><span class='nv'>popularity</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/r/utils/head.html'>head</a></span><span class='o'>(</span><span class='m'>10</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>mutate</span><span class='o'>(</span>name <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/factor.html'>factor</a></span><span class='o'>(</span><span class='nv'>name</span>, levels <span class='o'>=</span> <span class='nv'>name</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>ggplot</span><span class='o'>(</span><span class='nf'>aes</span><span class='o'>(</span>x <span class='o'>=</span> <span class='nv'>name</span>, y <span class='o'>=</span> <span class='nv'>popularity</span>, fill <span class='o'>=</span> <span class='nv'>name</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'>geom_bar</span><span class='o'>(</span>stat <span class='o'>=</span> <span class='s'>"identity"</span><span class='o'>)</span> <span class='o'>+</span> 
  <span class='nf'><a href='https://rdrr.io/pkg/ggimage/man/geom_image.html'>geom_image</a></span><span class='o'>(</span>
    <span class='nf'>aes</span><span class='o'>(</span>x <span class='o'>=</span> <span class='nv'>name</span>, y <span class='o'>=</span> <span class='nv'>popularity</span> <span class='o'>-</span> <span class='m'>70</span>, image <span class='o'>=</span> <span class='nv'>url</span><span class='o'>)</span>,
    size <span class='o'>=</span> <span class='m'>0.07</span>
  <span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'>ggtitle</span><span class='o'>(</span><span class='s'>"Marshal is the most popular villager"</span><span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'>theme</span><span class='o'>(</span>
    text <span class='o'>=</span> <span class='nf'>element_text</span><span class='o'>(</span>size <span class='o'>=</span> <span class='m'>16</span><span class='o'>)</span>,
    legend.position <span class='o'>=</span> <span class='s'>"none"</span>,
    axis.title.x <span class='o'>=</span> <span class='nf'>element_blank</span><span class='o'>(</span><span class='o'>)</span>,
    axis.text.x <span class='o'>=</span> <span class='nf'>element_text</span><span class='o'>(</span>angle <span class='o'>=</span> <span class='m'>90</span>, vjust <span class='o'>=</span> <span class='m'>0.5</span>, hjust <span class='o'>=</span> <span class='m'>1</span><span class='o'>)</span>,
    aspect.ratio <span class='o'>=</span> <span class='m'>1</span>
  <span class='o'>)</span> 
</code></pre>
<img src="figs/top-villagers-1.png" width="700px" style="display: block; margin: auto;" />

</div>

*Animal Crossing* villagers are sorted into 35 different species. Some are more loved than others. The popularity densities have long tails, so taking the `log` here makes them plot a lot better:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>villagers</span> <span class='o'>%&gt;%</span> 
    <span class='nf'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='o'>(</span><span class='nv'>species</span> <span class='o'>%in%</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"cat"</span>, <span class='s'>"chicken"</span>, <span class='s'>"squirrel"</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>ggplot</span><span class='o'>(</span><span class='nf'>aes</span><span class='o'>(</span>x <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/Log.html'>log</a></span><span class='o'>(</span><span class='nv'>popularity</span><span class='o'>)</span>, group <span class='o'>=</span> <span class='nv'>species</span>, fill <span class='o'>=</span> <span class='nv'>species</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>+</span> 
    <span class='nf'>geom_density</span><span class='o'>(</span>alpha <span class='o'>=</span> <span class='m'>0.4</span><span class='o'>)</span> <span class='o'>+</span>
    <span class='nf'>theme</span><span class='o'>(</span>text <span class='o'>=</span> <span class='nf'>element_text</span><span class='o'>(</span>size <span class='o'>=</span> <span class='m'>16</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>+</span>
    <span class='nf'>ggtitle</span><span class='o'>(</span><span class='s'>"Cats are more popular than chickens"</span><span class='o'>)</span>
</code></pre>
<img src="figs/species-popularity-1.png" width="700px" style="display: block; margin: auto;" />

</div>

Octopuses are particularly loved, though. There are only 3 octopus villagers, but their mean popularity is 366, as opposed to the overall mean popularity of 57. People really like [Zucker](https://animalcrossing.fandom.com/wiki/Zucker)!

## Authenticating with Google Cloud

By this point I've already set up an account and project with the Google Cloud Platform (GCP), and enabled the relevant APIs. I won't go into that detail here, since the GCP documentation is pretty good. However, I still need to authenticate myself to the GCP before I can use any of its services.

There's no all-encompassing R SDK for the Google Cloud Platform. [A few services can be used with packages provided by the CloudyR project](https://cloudyr.github.io/packages/index.html), but there's nothing for the Vision API. I'm happy to use Google's HTTP APIs directly, but the authentication usually trips me up. Fortunately, the `gargle` package is *excellent*, and makes the authentication much simpler than it would be to do it manually.

[Following the instructions provided by Google](https://cloud.google.com/docs/authentication/production), I created a service account with read/write access to Cloud Storage and permissions to use the Vision API. The actual credentials are kept in a JSON. Within my `.Renviron` file (hint: [`usethis::edit_r_environ()`](https://usethis.r-lib.org/reference/edit.html) will open this in RStudio) I set the "GOOGLE_APPLICATION_CREDENTIALS" environment variable to the path of this JSON. Now, I can use the `gargle` package to create a token with the appropriate scopes:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>gcp_token</span> <span class='o'>&lt;-</span> <span class='nf'>gargle</span><span class='nf'>::</span><span class='nf'><a href='https://gargle.r-lib.org/reference/credentials_service_account.html'>credentials_service_account</a></span><span class='o'>(</span>
  scopes <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span>
    <span class='s'>"https://www.googleapis.com/auth/cloud-vision"</span>,
    <span class='s'>"https://www.googleapis.com/auth/devstorage.read_write"</span>
  <span class='o'>)</span>,
  path <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/Sys.getenv.html'>Sys.getenv</a></span><span class='o'>(</span><span class='s'>"GOOGLE_APPLICATION_CREDENTIALS"</span><span class='o'>)</span>
<span class='o'>)</span></code></pre>

</div>

This token can be passed into `httr` verbs (in fact, it's a [`httr::TokenServiceAccount`](https://httr.r-lib.org/reference/Token-class.html)) where it will be used for authentication. `httr` handles all of the stuff I don't want to think about, like token refreshing and authentication headers.

## Uploading the images

I can query the Vision API with image data directly, but another option is to keep the thumbnails in a [Cloud Storage](https://cloud.google.com/storage) bucket. I created an `animal-crossing` bucket through the Google Cloud Platform console. I'll create a function for uploading villager images. I assume `villager` to be a single row of the `villagers` data frame, so that I can effectively treat it like a list. This function will:

1.  download `villager$url` to a temp file and use `on.exit` to clean up afterwards,
2.  define the name of the object I'm creating, using the villager's id,
3.  use [`httr::POST`](https://httr.r-lib.org/reference/POST.html) to post the image using my `gcp_token`, and finally
4.  check that the resulting status code is 200 (success)

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>upload_villager_image</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>villager</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>temp</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/tempfile.html'>tempfile</a></span><span class='o'>(</span><span class='o'>)</span>
  <span class='nf'><a href='https://rdrr.io/r/base/on.exit.html'>on.exit</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/unlink.html'>unlink</a></span><span class='o'>(</span><span class='nv'>temp</span><span class='o'>)</span><span class='o'>)</span>
  <span class='nf'><a href='https://rdrr.io/r/utils/download.file.html'>download.file</a></span><span class='o'>(</span><span class='nv'>villager</span><span class='o'>$</span><span class='nv'>url</span>, <span class='nv'>temp</span><span class='o'>)</span>
  <span class='nv'>object_name</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='o'>(</span><span class='nv'>villager</span><span class='o'>$</span><span class='nv'>id</span>, <span class='s'>".png"</span><span class='o'>)</span>

  <span class='nv'>response</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://httr.r-lib.org/reference/POST.html'>POST</a></span><span class='o'>(</span>
    <span class='nf'><a href='https://glue.tidyverse.org/reference/glue.html'>glue</a></span><span class='o'>(</span><span class='s'>"https://storage.googleapis.com/upload/storage/v1/b/animal-crossing/o?uploadType=media&amp;name=&#123;object_name&#125;"</span><span class='o'>)</span>,
    body <span class='o'>=</span> <span class='nf'><a href='https://httr.r-lib.org/reference/upload_file.html'>upload_file</a></span><span class='o'>(</span><span class='nv'>temp</span>, type <span class='o'>=</span> <span class='s'>"image/png"</span><span class='o'>)</span>,
    <span class='nf'><a href='https://httr.r-lib.org/reference/config.html'>config</a></span><span class='o'>(</span>token <span class='o'>=</span> <span class='nv'>gcp_token</span><span class='o'>)</span>
  <span class='o'>)</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://httr.r-lib.org/reference/status_code.html'>status_code</a></span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span> <span class='o'>!=</span> <span class='m'>200</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/stop.html'>stop</a></span><span class='o'>(</span><span class='nf'><a href='https://glue.tidyverse.org/reference/glue.html'>glue</a></span><span class='o'>(</span><span class='s'>"Upload of &#123;villager$id&#125; failed with status code &#123;status_code(response)&#125;"</span><span class='o'>)</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
<span class='o'>&#125;</span></code></pre>

</div>

If I can upload a single villager image, I can upload them all. I use `purrr` to iterate through the rows of the `villagers` data frame, uploading each of the 391 villager images.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>walk</span><span class='o'>(</span>
  <span class='m'>1</span><span class='o'>:</span><span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='o'>(</span><span class='nv'>villagers</span><span class='o'>)</span>,
  <span class='kr'>function</span><span class='o'>(</span><span class='nv'>row_index</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nv'>villager</span> <span class='o'>&lt;-</span> <span class='nv'>villagers</span><span class='o'>[</span><span class='nv'>row_index</span>,<span class='o'>]</span>
    <span class='nf'>upload_villager_image</span><span class='o'>(</span><span class='nv'>villager</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
<span class='o'>)</span></code></pre>

</div>

A quick aside: I don't often see code that uses `purrr` to iterate through the *rows* of a data frame like this, which makes me think I'm doing something unconventional. A better option may be to pull out `villager$name` and `villager$url`, and pass those as arguments to a binary `upload_villager_image` function.

## Annotating the villagers

With the images uploaded to Cloud Storage, I can query the Cloud Vision API with the path to a given thumbnail. For example, I can give `gs://animal-crossing/tangy.png` as an argument to the `images:annotate` endpoint.

The response is a list of labels, each consisting of a `description` (the label itself), a confidence `score` and a `topicality` score. I'll flatten this to a one-row data frame (`tibble`) of confidence scores, with columns the labels. This will make it easier to later concatenate the labels with the `villagers` data frame.

Note also the potential for the API to return duplicate labels --- in this case, I take the maximum `score`.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>annotate</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>villager_id</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>json</span> <span class='o'>&lt;-</span> <span class='nf'>jsonlite</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/jsonlite/man/fromJSON.html'>toJSON</a></span><span class='o'>(</span>
      <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>
          requests <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>
              image <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>
                  source <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>
                      gcsImageUri <span class='o'>=</span> <span class='nf'>glue</span><span class='nf'>::</span><span class='nf'><a href='https://glue.tidyverse.org/reference/glue.html'>glue</a></span><span class='o'>(</span><span class='s'>"gs://animal-crossing/&#123;villager_id&#125;.png"</span><span class='o'>)</span>
                  <span class='o'>)</span>
              <span class='o'>)</span>,
              features <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>
                  maxResults <span class='o'>=</span> <span class='m'>50</span>,
                  type <span class='o'>=</span> <span class='s'>"LABEL_DETECTION"</span>
              <span class='o'>)</span><span class='o'>)</span>
          <span class='o'>)</span>
      <span class='o'>)</span>,
      auto_unbox <span class='o'>=</span> <span class='kc'>TRUE</span>
  <span class='o'>)</span>
  
  <span class='nv'>response</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://httr.r-lib.org/reference/POST.html'>POST</a></span><span class='o'>(</span>
      <span class='s'>"https://vision.googleapis.com/v1/images:annotate"</span>,
      body <span class='o'>=</span> <span class='nv'>json</span>,
      <span class='nf'><a href='https://httr.r-lib.org/reference/config.html'>config</a></span><span class='o'>(</span>token <span class='o'>=</span> <span class='nv'>gcp_token</span><span class='o'>)</span>,
      <span class='nf'><a href='https://httr.r-lib.org/reference/add_headers.html'>add_headers</a></span><span class='o'>(</span>`Content-Type` <span class='o'>=</span> <span class='s'>"application/json; charset=utf-8"</span><span class='o'>)</span>
  <span class='o'>)</span>
  
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://httr.r-lib.org/reference/status_code.html'>status_code</a></span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span> <span class='o'>!=</span> <span class='m'>200</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='kr'><a href='https://rdrr.io/r/base/stop.html'>stop</a></span><span class='o'>(</span><span class='s'>"Error labelling "</span>, <span class='nv'>villager</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
  
  <span class='nf'><a href='https://httr.r-lib.org/reference/content.html'>content</a></span><span class='o'>(</span><span class='nv'>response</span><span class='o'>)</span><span class='o'>$</span><span class='nv'>responses</span><span class='o'>[[</span><span class='m'>1</span><span class='o'>]</span><span class='o'>]</span><span class='o'>$</span><span class='nv'>labelAnnotations</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>map</span><span class='o'>(</span><span class='nv'>as_tibble</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>reduce</span><span class='o'>(</span><span class='nv'>bind_rows</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>select</span><span class='o'>(</span><span class='nv'>description</span>, <span class='nv'>score</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>pivot_wider</span><span class='o'>(</span>names_from <span class='o'>=</span> <span class='nv'>description</span>, values_from <span class='o'>=</span> <span class='nv'>score</span>, values_fn <span class='o'>=</span> <span class='nv'>max</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>janitor</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/janitor/man/clean_names.html'>clean_names</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

I ask for 50 labels, but the API *appears* not return labels with a confidence score of less than 0.5, so I may get fewer:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>annotate</span><span class='o'>(</span><span class='s'>"audie"</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 1 x 19</span></span>
<span class='c'>#&gt;    head   toy cartoon fashion_design   art sunglasses electric_blue eyewear</span>
<span class='c'>#&gt;   <span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>   </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>          </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>      </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>         </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span><span>   </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>1</span><span> 0.972 0.921   0.812          0.808 0.801      0.746         0.741   0.699</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 11 more variables: magenta &lt;dbl&gt;, fictional_character &lt;dbl&gt;,</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>#   goggles &lt;dbl&gt;, doll &lt;dbl&gt;, pattern &lt;dbl&gt;, entertainment &lt;dbl&gt;,</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>#   figurine &lt;dbl&gt;, visual_arts &lt;dbl&gt;, performing_arts &lt;dbl&gt;, child_art &lt;dbl&gt;,</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>#   painting &lt;dbl&gt;</span></span></code></pre>

</div>

This isn't very pretty to look at, so I'll make a nice plot:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>plot_villager</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>villager_id</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>villager</span> <span class='o'>&lt;-</span> <span class='nv'>villagers</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/r/stats/filter.html'>filter</a></span><span class='o'>(</span><span class='nv'>id</span> <span class='o'>==</span> <span class='nv'>villager_id</span><span class='o'>)</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='o'>(</span><span class='nv'>villager</span><span class='o'>)</span> <span class='o'>==</span> <span class='m'>0</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/stop.html'>stop</a></span><span class='o'>(</span><span class='s'>"Couldn't find villager with id "</span>, <span class='nv'>villager_id</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
  
  <span class='nv'>villager_plot</span> <span class='o'>&lt;-</span> <span class='nv'>villager_id</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>annotate</span><span class='o'>(</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>pivot_longer</span><span class='o'>(</span><span class='nf'>everything</span><span class='o'>(</span><span class='o'>)</span>, names_to <span class='o'>=</span> <span class='s'>"label"</span>, values_to <span class='o'>=</span> <span class='s'>"score"</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>top_n</span><span class='o'>(</span><span class='m'>8</span>, wt <span class='o'>=</span> <span class='nv'>score</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>mutate</span><span class='o'>(</span>label <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/factor.html'>factor</a></span><span class='o'>(</span><span class='nv'>label</span>, levels <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/rev.html'>rev</a></span><span class='o'>(</span><span class='nv'>.</span><span class='o'>$</span><span class='nv'>label</span><span class='o'>)</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>ggplot</span><span class='o'>(</span><span class='nf'>aes</span><span class='o'>(</span>x <span class='o'>=</span> <span class='nv'>label</span>, y <span class='o'>=</span> <span class='nv'>score</span>, fill <span class='o'>=</span> <span class='nv'>label</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>+</span>
    <span class='nf'>geom_bar</span><span class='o'>(</span>stat <span class='o'>=</span> <span class='s'>"identity"</span><span class='o'>)</span> <span class='o'>+</span>
    <span class='nf'>scale_fill_brewer</span><span class='o'>(</span>palette<span class='o'>=</span><span class='s'>"Set1"</span><span class='o'>)</span> <span class='o'>+</span>
    <span class='nf'>theme</span><span class='o'>(</span>
      legend.position <span class='o'>=</span> <span class='s'>"none"</span>,
      axis.title.x <span class='o'>=</span> <span class='nf'>element_blank</span><span class='o'>(</span><span class='o'>)</span>,
      axis.title.y <span class='o'>=</span> <span class='nf'>element_blank</span><span class='o'>(</span><span class='o'>)</span>,
      axis.text <span class='o'>=</span> <span class='nf'>element_text</span><span class='o'>(</span>size <span class='o'>=</span> <span class='m'>20</span><span class='o'>)</span>,
      plot.title <span class='o'>=</span> <span class='nf'>element_text</span><span class='o'>(</span>size <span class='o'>=</span> <span class='m'>32</span><span class='o'>)</span>
    <span class='o'>)</span> <span class='o'>+</span>
    <span class='nf'>ggtitle</span><span class='o'>(</span><span class='nv'>villager</span><span class='o'>$</span><span class='nv'>name</span><span class='o'>)</span> <span class='o'>+</span>
    <span class='nf'>coord_flip</span><span class='o'>(</span><span class='o'>)</span>

  <span class='nv'>villager_image</span> <span class='o'>&lt;-</span> <span class='nf'>png</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/png/man/readPNG.html'>readPNG</a></span><span class='o'>(</span>
    <span class='nf'>curl</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/curl/man/curl_fetch.html'>curl_fetch_memory</a></span><span class='o'>(</span><span class='nv'>villager</span><span class='o'>$</span><span class='nv'>url</span><span class='o'>)</span><span class='o'>$</span><span class='nv'>content</span>,
    native <span class='o'>=</span> <span class='kc'>TRUE</span>
  <span class='o'>)</span>
  
  <span class='nv'>villager_plot</span> <span class='o'>+</span> <span class='nv'>villager_image</span>
<span class='o'>&#125;</span></code></pre>

</div>

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>plot_villager</span><span class='o'>(</span><span class='s'>"audie"</span><span class='o'>)</span>
</code></pre>
<img src="figs/plot-audie-1.png" width="700px" style="display: block; margin: auto;" />

</div>

# An attempt at machine learning

Readers of my blog should expect this by now, but I tend not to care about model accuracy in these posts. My interest is always in the process of building a model, rather than the model itself. A warning ahead: the model I'm about to train here will perform terribly.

I don't believe model tuning or trying different techniques would help here. The dataset is very sparse and wide, so there's not a lot of information to model.

## Label all villagers

I've defined a function for annotating a single villager, but I have 391 to label. [Google Cloud does have a batch annotation API](https://cloud.google.com/vision/docs/batch), but I decided to save the coding effort and just re-use my single-villager annotation function with `purrr`.

The following can take a few minutes. At times progress was stalling, and I suspect I was brushing up against some API limits. The [`Sys.sleep(0.5)`](https://rdrr.io/r/base/Sys.sleep.html) is intended to address that, but I'm only speculating.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>labels</span> <span class='o'>&lt;-</span> <span class='nf'>map</span><span class='o'>(</span><span class='nv'>villagers</span><span class='o'>$</span><span class='nv'>id</span>, <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='o'>&#123;</span><span class='nf'><a href='https://rdrr.io/r/base/Sys.sleep.html'>Sys.sleep</a></span><span class='o'>(</span><span class='m'>0.5</span><span class='o'>)</span>; <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='nf'>annotate</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span><span class='o'>)</span><span class='o'>&#125;</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>reduce</span><span class='o'>(</span><span class='nv'>bind_rows</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>rename_all</span><span class='o'>(</span><span class='o'>~</span><span class='nf'><a href='https://glue.tidyverse.org/reference/glue.html'>glue</a></span><span class='o'>(</span><span class='s'>"label_&#123;.x&#125;"</span><span class='o'>)</span><span class='o'>)</span></code></pre>

</div>

I've prefixed every label with "label\_" so that I can identify these columns later in data pre-processing. Setting up a sensible column naming convention will let me use the powerful [`tidyselect::starts_with`](https://tidyselect.r-lib.org/reference/starts_with.html) selector.

`labels` is a wide data frame with 413 columns. But 94% entries are `NA`. This is because the Cloud Vision API returns only the labels it deems most relevant. It also seems to not return any labels with a "score" of less than 0.5. The end result of [`dplyr::bind_rows`](https://dplyr.tidyverse.org/reference/bind.html) is a wide, sparse data frame of floats and `NA`s.

I'll have to deal with this problem in pre-processing. For now I'll combine `labels` with the `villagers` data frame:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>villagers_labelled</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/cbind.html'>cbind</a></span><span class='o'>(</span><span class='nv'>villagers</span>, <span class='nv'>labels</span><span class='o'>)</span>
<span class='nf'><a href='https://rdrr.io/r/base/dim.html'>dim</a></span><span class='o'>(</span><span class='nv'>villagers_labelled</span><span class='o'>)</span>
<span class='c'>#&gt; [1] 391 425</span></code></pre>

</div>

## Pre-processing

I'll use the `recipes` package to pre-process the data before modelling. This is one of my favourite packages, and a real star of `tidymodels`. First I'll do a simple `train`/`test` split, since my pre-processing strategy can't depend on the `test` data:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>split</span> <span class='o'>&lt;-</span> <span class='nf'>initial_split</span><span class='o'>(</span><span class='nv'>villagers_labelled</span>, prop <span class='o'>=</span> <span class='m'>0.8</span><span class='o'>)</span>
<span class='nv'>train</span> <span class='o'>&lt;-</span> <span class='nf'>training</span><span class='o'>(</span><span class='nv'>split</span><span class='o'>)</span>
<span class='nf'><a href='https://rdrr.io/r/base/dim.html'>dim</a></span><span class='o'>(</span><span class='nv'>train</span><span class='o'>)</span>
<span class='c'>#&gt; [1] 312 425</span>
<span class='nv'>test</span> <span class='o'>&lt;-</span> <span class='nf'>testing</span><span class='o'>(</span><span class='nv'>split</span><span class='o'>)</span>
<span class='nf'><a href='https://rdrr.io/r/base/dim.html'>dim</a></span><span class='o'>(</span><span class='nv'>test</span><span class='o'>)</span>
<span class='c'>#&gt; [1]  79 425</span></code></pre>

</div>

To mitigate the impact of the sparsity, I'll remove any labels that are blank more than half the time in the training data. I'll make a note of these now:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>too_many_missing</span> <span class='o'>&lt;-</span> <span class='nv'>train</span> <span class='o'>%&gt;%</span>
  <span class='nf'>select</span><span class='o'>(</span><span class='nf'>starts_with</span><span class='o'>(</span><span class='s'>"label"</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>select_if</span><span class='o'>(</span><span class='o'>~</span><span class='nf'><a href='https://rdrr.io/r/base/sum.html'>sum</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='o'>(</span><span class='nv'>.x</span><span class='o'>)</span><span class='o'>)</span><span class='o'>/</span><span class='nf'><a href='https://rdrr.io/r/base/length.html'>length</a></span><span class='o'>(</span><span class='nv'>.x</span><span class='o'>)</span> <span class='o'>&gt;</span> <span class='m'>0.5</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://rdrr.io/r/base/colnames.html'>colnames</a></span><span class='o'>(</span><span class='o'>)</span></code></pre>

</div>

I can't find documentation to confirm this, but it appears as though the Google Cloud Vision API won't return a label with a score of less than 0.5. One way to deal with the sparsity of these labels is to binarise them --- `TRUE` if the label is *present*, otherwise `FALSE`. This turns the labels into features that effectively say, "Did the Cloud Vision API detect this label?".

Species is also a difficult predictor here --- in the training set there are 35 different species amongst 312 villagers. I'll collapse the uncommon species into an "other" category.

The remaining pre-processing steps are fairly standard --- discarding unneeded columns, converting strings to factors, and applying one-hot encoding. I'll also keep using [`log(popularity)`](https://rdrr.io/r/base/Log.html) here, to deal with those long tails in the popularity scores.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pre_processing</span> <span class='o'>&lt;-</span> <span class='nf'>recipe</span><span class='o'>(</span><span class='nv'>train</span>, <span class='nv'>popularity</span> <span class='o'>~</span> <span class='nv'>.</span><span class='o'>)</span> <span class='o'>%&gt;%</span>
  <span class='nf'>step_rm</span><span class='o'>(</span><span class='nv'>row_n</span>, <span class='nv'>id</span>, <span class='nv'>name</span>, <span class='nv'>birthday</span>, <span class='nv'>song</span>, <span class='nv'>phrase</span>, <span class='nv'>full_id</span>, <span class='nv'>url</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>step_rm</span><span class='o'>(</span><span class='nf'>one_of</span><span class='o'>(</span><span class='nv'>too_many_missing</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>step_mutate_at</span><span class='o'>(</span><span class='nf'>starts_with</span><span class='o'>(</span><span class='s'>"label"</span><span class='o'>)</span>, fn <span class='o'>=</span> <span class='o'>~</span><span class='nf'><a href='https://rdrr.io/r/base/integer.html'>as.integer</a></span><span class='o'>(</span><span class='o'>!</span><span class='nf'><a href='https://rdrr.io/r/base/NA.html'>is.na</a></span><span class='o'>(</span><span class='nv'>.x</span><span class='o'>)</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>step_string2factor</span><span class='o'>(</span><span class='nf'>has_type</span><span class='o'>(</span><span class='s'>"character"</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>step_other</span><span class='o'>(</span><span class='nv'>species</span>, threshold <span class='o'>=</span> <span class='m'>0.03</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>step_dummy</span><span class='o'>(</span><span class='nf'>all_nominal_predictors</span><span class='o'>(</span><span class='o'>)</span>, one_hot <span class='o'>=</span> <span class='kc'>TRUE</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>step_log</span><span class='o'>(</span><span class='nv'>popularity</span>, skip <span class='o'>=</span> <span class='kc'>TRUE</span><span class='o'>)</span></code></pre>

</div>

## An `xgboost` model

The processed `train` data has 37 columns, but is of (matrix) rank 34. Informally, this means that the training data is bigger than the information it contains. Linear models will throw warnings here. Tree-based methods will hide the problem, but there's no escaping the fact that any model trained on this data will be terrible.

I'll set up an `xgboost` model with the `parsnip` package, allowing for tuning the `tree_depth` and `mtry` parameters. Here, `mtry` refers to the number of predictors available to the model at each split. Finally, I'll combine the pre-processing and the model into a `workflow`.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>xgboost_model</span> <span class='o'>&lt;-</span> <span class='nf'>boost_tree</span><span class='o'>(</span>trees <span class='o'>=</span> <span class='m'>200</span>, mtry <span class='o'>=</span> <span class='nf'>tune</span><span class='o'>(</span><span class='o'>)</span>, tree_depth <span class='o'>=</span> <span class='nf'>tune</span><span class='o'>(</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>set_engine</span><span class='o'>(</span><span class='s'>"xgboost"</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>set_mode</span><span class='o'>(</span><span class='s'>"regression"</span><span class='o'>)</span>

<span class='nv'>xgboost_workflow</span> <span class='o'>&lt;-</span> <span class='nf'>workflow</span><span class='o'>(</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>add_recipe</span><span class='o'>(</span><span class='nv'>pre_processing</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>add_model</span><span class='o'>(</span><span class='nv'>xgboost_model</span><span class='o'>)</span>
<span class='nv'>xgboost_workflow</span>
<span class='c'>#&gt; ══ Workflow ════════════════════════════════════════════════════════════════════</span>
<span class='c'>#&gt; <span style='font-style: italic;'>Preprocessor:</span><span> Recipe</span></span>
<span class='c'>#&gt; <span style='font-style: italic;'>Model:</span><span> boost_tree()</span></span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ── Preprocessor ────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt; 7 Recipe Steps</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; • step_rm()</span>
<span class='c'>#&gt; • step_rm()</span>
<span class='c'>#&gt; • step_mutate_at()</span>
<span class='c'>#&gt; • step_string2factor()</span>
<span class='c'>#&gt; • step_other()</span>
<span class='c'>#&gt; • step_dummy()</span>
<span class='c'>#&gt; • step_log()</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ── Model ───────────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt; Boosted Tree Model Specification (regression)</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; Main Arguments:</span>
<span class='c'>#&gt;   mtry = tune()</span>
<span class='c'>#&gt;   trees = 200</span>
<span class='c'>#&gt;   tree_depth = tune()</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; Computational engine: xgboost</span></code></pre>

</div>

I'll tune the model, relying on the default grid for `tree_depth` and `mtry`, and using 5-fold cross-validation:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>folds</span> <span class='o'>&lt;-</span> <span class='nf'>vfold_cv</span><span class='o'>(</span><span class='nv'>train</span>, v <span class='o'>=</span> <span class='m'>5</span><span class='o'>)</span>
<span class='nv'>tune_results</span> <span class='o'>&lt;-</span> <span class='nf'>tune_grid</span><span class='o'>(</span><span class='nv'>xgboost_workflow</span>, resamples <span class='o'>=</span> <span class='nv'>folds</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #0000BB;'>i</span><span> </span><span style='color: #000000;'>Creating pre-processing data to finalize unknown parameter: mtry</span></span></code></pre>

</div>

I'll use whichever `mtry` and `tree_depth` parameters minimise root mean-squared error to finalise my `workflow`, and fit it to the `train` data.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>fitted_xgboost_workflow</span> <span class='o'>&lt;-</span> <span class='nv'>xgboost_workflow</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>finalize_workflow</span><span class='o'>(</span><span class='nf'>select_best</span><span class='o'>(</span><span class='nv'>tune_results</span>, metric <span class='o'>=</span> <span class='s'>"rmse"</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>fit</span><span class='o'>(</span><span class='nv'>train</span><span class='o'>)</span></code></pre>

</div>

It's time to see just how bad this model is. Recall that I took the `log` of the popularity in the training data, so to truly evaluate the performance I have to take the `exp` of the predictions.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>test_performance</span> <span class='o'>&lt;-</span> <span class='nv'>test</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>mutate</span><span class='o'>(</span>
    predicted <span class='o'>=</span>  <span class='nf'><a href='https://rdrr.io/r/stats/predict.html'>predict</a></span><span class='o'>(</span><span class='nv'>fitted_xgboost_workflow</span>, <span class='nv'>test</span><span class='o'>)</span><span class='o'>$</span><span class='nv'>.pred</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/r/base/Log.html'>exp</a></span><span class='o'>(</span><span class='o'>)</span>,
    residual <span class='o'>=</span> <span class='nv'>popularity</span> <span class='o'>-</span> <span class='nv'>predicted</span>
  <span class='o'>)</span>
<span class='nf'>metric_set</span><span class='o'>(</span><span class='nv'>rmse</span>, <span class='nv'>mae</span><span class='o'>)</span><span class='o'>(</span><span class='nv'>test_performance</span>, <span class='nv'>popularity</span>, <span class='nv'>predicted</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 2 x 3</span></span>
<span class='c'>#&gt;   .metric .estimator .estimate</span>
<span class='c'>#&gt;   <span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>   </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>          </span><span style='color: #555555;font-style: italic;'>&lt;dbl&gt;</span></span>
<span class='c'>#&gt; <span style='color: #555555;'>1</span><span> rmse    standard       108. </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>2</span><span> mae     standard        58.0</span></span></code></pre>

</div>

Oof, that model is pretty bad. I wonder if it's because the distribution of popularity isn't uniform? I'll compare the predicted and actual values to see if there's a difference at the extreme ends:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>test_performance</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>ggplot</span><span class='o'>(</span><span class='nf'>aes</span><span class='o'>(</span>x <span class='o'>=</span> <span class='nv'>predicted</span>, y <span class='o'>=</span> <span class='nv'>popularity</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>+</span> 
  <span class='nf'>geom_point</span><span class='o'>(</span><span class='o'>)</span> <span class='o'>+</span>
  <span class='nf'>geom_abline</span><span class='o'>(</span>intercept <span class='o'>=</span> <span class='m'>0</span>, slope <span class='o'>=</span> <span class='m'>1</span><span class='o'>)</span>
</code></pre>
<img src="figs/predicted-vs-actual-1.png" width="700px" style="display: block; margin: auto;" />

</div>

Sure enough, that seems to be the case. For values below about 50, the model seems to be *not too bad*, and certainly better than it performs for the more popular villagers.

## Model interpretability

I tried to use some model interpretability techniques to see what effect these labels were having on villager popularity. Unfortunately, I had trouble applying either LIME or SHAP:

-   The `lime` package throws many, many warnings. I'm not surprised. The inputs are rank-deficient matrices and the LIME technique uses on linear models.
-   The `shapr` package doesn't support explanations for more than 30 features.

I'll show the results of my `lime` analysis here, with the understanding that the results are almost certainly nonsense.

First I'll separate the pre-processing function and model object from the workflow, since `lime` (nor `shapr`) can't handle the in-built pre-processing of a `workflow` object:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>pre_processing_function</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nf'>pull_workflow_prepped_recipe</span><span class='o'>(</span><span class='nv'>fitted_xgboost_workflow</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>bake</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
    <span class='nf'>select</span><span class='o'>(</span><span class='o'>-</span><span class='nv'>popularity</span><span class='o'>)</span>
<span class='o'>&#125;</span>

<span class='nv'>fitted_xgboost_model</span> <span class='o'>&lt;-</span> <span class='nf'>pull_workflow_fit</span><span class='o'>(</span><span class='nv'>fitted_xgboost_workflow</span><span class='o'>)</span></code></pre>

</div>

Then I fit the explainer. The quantile binning approach just doesn't work with such sparse data, so I disable it.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>explainer</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://lime.data-imaginist.com/reference/lime.html'>lime</a></span><span class='o'>(</span>
  <span class='nf'>pre_processing_function</span><span class='o'>(</span><span class='nv'>train</span><span class='o'>)</span>,
  <span class='nv'>fitted_xgboost_model</span>,
  quantile_bins <span class='o'>=</span> <span class='kc'>FALSE</span>
<span class='o'>)</span></code></pre>

</div>

Now I'll explain a few test cases and plot the results. I'll suppress the warnings that would usually appear here.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>test_case</span> <span class='o'>&lt;-</span> <span class='nf'>sample_n</span><span class='o'>(</span><span class='nv'>test</span>, <span class='m'>10</span><span class='o'>)</span>

<span class='nv'>explanations</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/warning.html'>suppressWarnings</a></span><span class='o'>(</span>
  <span class='nf'><a href='https://lime.data-imaginist.com/reference/explain.html'>explain</a></span><span class='o'>(</span>
    <span class='nf'>pre_processing_function</span><span class='o'>(</span><span class='nv'>test_case</span><span class='o'>)</span>,
    <span class='nv'>explainer</span>,
    n_features <span class='o'>=</span> <span class='m'>6</span>
  <span class='o'>)</span>
<span class='o'>)</span>

<span class='nf'><a href='https://lime.data-imaginist.com/reference/plot_explanations.html'>plot_explanations</a></span><span class='o'>(</span><span class='nv'>explanations</span><span class='o'>)</span> <span class='o'>+</span> 
  <span class='nf'>scale_x_discrete</span><span class='o'>(</span>labels <span class='o'>=</span> <span class='nv'>test_case</span><span class='o'>$</span><span class='nv'>name</span><span class='o'>)</span>
</code></pre>
<img src="figs/explanation-1.png" width="700px" style="display: block; margin: auto;" />

</div>

------------------------------------------------------------------------

The *Animal Crossing* franchise and its fictional characters are the property of Nintendo. The thumbnail images of Animal Crossing villagers on this page are used for the purposes of study and commentary.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/sessioninfo/man/session_info.html'>session_info</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; ─ Session info ───────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  setting  value                       </span>
<span class='c'>#&gt;  version  R version 4.1.0 (2021-05-18)</span>
<span class='c'>#&gt;  os       macOS Big Sur 11.3          </span>
<span class='c'>#&gt;  system   aarch64, darwin20           </span>
<span class='c'>#&gt;  ui       X11                         </span>
<span class='c'>#&gt;  language (EN)                        </span>
<span class='c'>#&gt;  collate  en_AU.UTF-8                 </span>
<span class='c'>#&gt;  ctype    en_AU.UTF-8                 </span>
<span class='c'>#&gt;  tz       Australia/Melbourne         </span>
<span class='c'>#&gt;  date     2021-06-07                  </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ─ Packages ───────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  package      * version    date       lib source                         </span>
<span class='c'>#&gt;  askpass        1.1        2019-01-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  assertthat     0.2.1      2019-03-21 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  backports      1.2.1      2020-12-09 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  BiocManager    1.30.15    2021-05-11 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  broom        * 0.7.6      2021-04-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cachem         1.0.4      2021-02-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  callr          3.7.0      2021-04-20 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cellranger     1.1.0      2016-07-27 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  class          7.3-19     2021-05-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cli            2.5.0      2021-04-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  codetools      0.2-18     2020-11-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  colorspace     2.0-1      2021-05-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  crayon         1.4.1      2021-02-08 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  curl           4.3.1      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  data.table     1.14.0     2021-02-21 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  DBI            1.1.1      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  dbplyr         2.1.1      2021-04-06 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  desc           1.3.0      2021-03-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  devtools       2.4.0      2021-04-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  dials        * 0.0.9      2020-09-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  DiceDesign     1.9        2021-02-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  digest         0.6.27     2020-10-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  downlit        0.2.1      2020-11-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  dplyr        * 1.0.5      2021-03-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ellipsis       0.3.2      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  evaluate       0.14       2019-05-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fansi          0.4.2      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  farver         2.1.0      2021-02-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fastmap        1.1.0      2021-01-25 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  forcats      * 0.5.1      2021-01-27 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  foreach        1.5.1      2020-10-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fs             1.5.0      2020-07-31 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  furrr          0.2.2      2021-01-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  future         1.21.0     2020-12-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  gargle         1.1.0      2021-04-02 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  generics       0.1.0      2020-10-31 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ggimage      * 0.2.8      2020-04-02 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ggplot2      * 3.3.3      2020-12-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ggplotify      0.0.7      2021-05-11 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  glmnet         4.1-1      2021-02-21 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  globals        0.14.0     2020-11-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  glue         * 1.4.2      2020-08-27 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  gower          0.2.2      2020-06-23 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  GPfit          1.0-8      2019-02-08 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  gridGraphics   0.5-1      2020-12-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  gtable         0.3.0      2019-03-25 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  hardhat        0.1.5      2020-11-09 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  haven          2.4.1      2021-04-23 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  highr          0.9        2021-04-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  hms            1.0.0      2021-01-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  htmltools      0.5.1.1    2021-01-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  httr         * 1.4.2      2020-07-20 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  hugodown       0.0.0.9000 2021-05-16 [1] Github (r-lib/hugodown@97ea0cd)</span>
<span class='c'>#&gt;  infer        * 0.5.4      2021-01-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ipred          0.9-11     2021-03-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  iterators      1.0.13     2020-10-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  jsonlite       1.7.2      2020-12-09 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  knitr          1.33       2021-04-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  labeling       0.4.2      2020-10-20 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lattice        0.20-44    2021-05-02 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lava           1.6.9      2021-03-11 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lhs            1.1.1      2020-10-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lifecycle      1.0.0      2021-02-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lime         * 0.5.2      2021-02-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  listenv        0.8.0      2019-12-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lubridate      1.7.10     2021-02-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  magick         2.7.2      2021-05-02 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  magrittr       2.0.1      2020-11-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  MASS           7.3-54     2021-05-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  Matrix         1.3-3      2021-05-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  memoise        2.0.0      2021-01-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  modeldata    * 0.1.0      2020-10-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  modelr         0.1.8      2020-05-19 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  munsell        0.5.0      2018-06-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  nnet           7.3-16     2021-05-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  openssl        1.4.4      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  parallelly     1.25.0     2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  parsnip      * 0.1.6      2021-05-27 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  patchwork    * 1.1.1      2020-12-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pillar         1.6.1      2021-05-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgbuild       1.2.0      2020-12-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgconfig      2.0.3      2019-09-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgload        1.2.1      2021-04-06 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  plyr           1.8.6      2020-03-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  prettyunits    1.1.1      2020-01-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pROC           1.17.0.1   2021-01-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  processx       3.5.2      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  prodlim        2019.11.13 2019-11-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ps             1.6.0      2021-02-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  purrr        * 0.3.4      2020-04-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  R6             2.5.0      2020-10-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  Rcpp           1.0.6      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  readr        * 1.4.0      2020-10-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  readxl         1.3.1      2019-03-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  recipes      * 0.1.16     2021-04-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  remotes        2.3.0      2021-04-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  reprex         2.0.0      2021-04-02 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rlang          0.4.11     2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rmarkdown      2.8        2021-05-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rpart          4.1-15     2019-04-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rprojroot      2.0.2      2020-11-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rsample      * 0.1.0      2021-05-08 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rstudioapi     0.13       2020-11-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rvcheck        0.1.8      2020-03-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rvest          1.0.0      2021-03-09 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  scales       * 1.1.1      2020-05-11 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  sessioninfo    1.1.1      2018-11-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  shape          1.4.6      2021-05-19 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  stringi        1.6.1      2021-05-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  stringr      * 1.4.0      2019-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  survival       3.2-11     2021-04-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  testthat       3.0.2      2021-02-14 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tibble       * 3.1.2      2021-05-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tidymodels   * 0.1.3      2021-04-19 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tidyr        * 1.1.3      2021-03-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tidyselect     1.1.1      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tidyverse    * 1.3.1      2021-04-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  timeDate       3043.102   2018-02-21 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tune         * 0.1.5      2021-04-23 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  usethis        2.0.1      2021-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  utf8           1.2.1      2021-03-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  vctrs          0.3.8      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  withr          2.4.2      2021-04-18 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  workflows    * 0.2.2      2021-03-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  workflowsets * 0.0.2      2021-04-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  xfun           0.22       2021-03-11 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  xgboost        1.4.1.1    2021-04-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  xml2           1.3.2      2020-04-23 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  yaml           2.2.1      2020-02-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  yardstick    * 0.0.8      2021-03-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; [1] /Library/Frameworks/R.framework/Versions/4.1-arm64/Resources/library</span></code></pre>

</div>

