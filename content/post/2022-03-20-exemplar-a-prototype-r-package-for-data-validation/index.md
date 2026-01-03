---
title: "Exemplar: a prototype R package for data validation"
author: ~
date: '2022-03-20'
slug: exemplar-a-prototype-r-package-for-data-validation
category: code
tags:
    - R
featured: "/img/featured/magnifying-glass.webp"
output: hugodown::md_document
rmd_hash: e9a12e10e6adfe4d

---

I've been playing around with an idea for a new R package. I call it `exemplar` and here's how it works: I provide an example of what data should look like --- an *exemplar*. The package gives a function that checks to make sure that any new data looks the same. The generated function checks --- for each column --- duplicate values, missing values, ranges, and more.

The validation function doesn't have any dependencies at all. I need `exemplar` to generate it, but not to use it.

In this post I'll give some examples of how it works and what sort of things are validated.

I doubt I'll ever submit `exemplar` to CRAN. What I've done here isn't substantial enough to justify a CRAN submission, and it's a fairly niche tool. I'm happy to be convinced otherwise, but for now this will stay on Github and can be installed with:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>remotes</span><span class='nf'>::</span><span class='nf'><a href='https://remotes.r-lib.org/reference/install_github.html'>install_github</a></span><span class='o'>(</span><span class='s'>"mdneuzerling/exemplar"</span><span class='o'>)</span></code></pre>

</div>

I'll also be using the `tidyselect` package for the examples below. I'll load that now. Most people never load this package directly, but it's one of the main components of `dplyr`.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='kr'><a href='https://rdrr.io/r/base/library.html'>library</a></span><span class='o'>(</span><span class='nv'><a href='https://tidyselect.r-lib.org'>tidyselect</a></span><span class='o'>)</span></code></pre>

</div>

## Some examples

The generated validation functions for data frames can get pretty long, since it includes checks for each column. To keep things brief I'll check just the `wt` and `mpg` columns of `mtcars`:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nv'>mtcars</span>, <span class='nv'>wt</span>, <span class='nv'>mpg</span><span class='o'>)</span>
<span class='c'>#&gt; validate_mtcars <span style='color: #00BB00;'>&lt;-</span> <span style='color: #BB0000;'>function</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span> <span style='color: #BBBB00;'>&#123;</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>stopifnot</span><span style='color: #0000BB;'>(</span>exprs = <span style='color: #00BBBB;'>&#123;</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>is.data.frame</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># The data is potentially being subsetted so this assertion has been disabled:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># identical(colnames(data), c("wt", "mpg"))</span></span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt;     <span style='color: #BBBB00;'>"wt"</span> <span style='color: #00BB00;'>%in%</span> <span style='color: #00BBBB;'>colnames</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>is.double</span><span style='color: #BBBB00;'>(</span>data<span style='color: #0000BB;'>[[</span><span style='color: #BBBB00;'>"wt"</span><span style='color: #0000BB;'>]]</span><span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #00BB00;'>!</span><span style='color: #00BBBB;'>any</span><span style='color: #BBBB00;'>(</span><span style='color: #00BBBB;'>is.na</span><span style='color: #0000BB;'>(</span>data<span style='color: #00BBBB;'>[[</span><span style='color: #BBBB00;'>"wt"</span><span style='color: #00BBBB;'>]]</span><span style='color: #0000BB;'>)</span> <span style='color: #00BB00;'>|</span> <span style='color: #00BBBB;'>is.null</span><span style='color: #0000BB;'>(</span>data<span style='color: #00BBBB;'>[[</span><span style='color: #BBBB00;'>"wt"</span><span style='color: #00BBBB;'>]]</span><span style='color: #0000BB;'>)</span><span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># Duplicate values were detected so this assertion has been disabled:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># !any(duplicated(data[["wt"]]))</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>min</span><span style='color: #BBBB00;'>(</span>data<span style='color: #0000BB;'>[[</span><span style='color: #BBBB00;'>"wt"</span><span style='color: #0000BB;'>]]</span>, na.rm = <span style='color: #0000BB;'>TRUE</span><span style='color: #BBBB00;'>)</span> <span style='color: #00BB00;'>&gt;</span> <span style='color: #0000BB;'>0</span> <span style='color: #555555; font-style: italic;'># all positive</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below range assertions if needed:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data[["wt"]], na.rm = TRUE) &lt;= 5.424</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># 1.513 &lt;= min(data[["wt"]], na.rm = TRUE)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below deviance assertions if needed.</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># The mean is 3.22 and the standard deviation is 0.98:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data[["wt"]], na.rm = TRUE) &lt;= 3.22 + 4 * 0.98</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># 3.22 - 4 * 0.98 &lt;= max(data[["wt"]], na.rm = TRUE)</span></span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt;     <span style='color: #BBBB00;'>"mpg"</span> <span style='color: #00BB00;'>%in%</span> <span style='color: #00BBBB;'>colnames</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>is.double</span><span style='color: #BBBB00;'>(</span>data<span style='color: #0000BB;'>[[</span><span style='color: #BBBB00;'>"mpg"</span><span style='color: #0000BB;'>]]</span><span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #00BB00;'>!</span><span style='color: #00BBBB;'>any</span><span style='color: #BBBB00;'>(</span><span style='color: #00BBBB;'>is.na</span><span style='color: #0000BB;'>(</span>data<span style='color: #00BBBB;'>[[</span><span style='color: #BBBB00;'>"mpg"</span><span style='color: #00BBBB;'>]]</span><span style='color: #0000BB;'>)</span> <span style='color: #00BB00;'>|</span> <span style='color: #00BBBB;'>is.null</span><span style='color: #0000BB;'>(</span>data<span style='color: #00BBBB;'>[[</span><span style='color: #BBBB00;'>"mpg"</span><span style='color: #00BBBB;'>]]</span><span style='color: #0000BB;'>)</span><span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># Duplicate values were detected so this assertion has been disabled:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># !any(duplicated(data[["mpg"]]))</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>min</span><span style='color: #BBBB00;'>(</span>data<span style='color: #0000BB;'>[[</span><span style='color: #BBBB00;'>"mpg"</span><span style='color: #0000BB;'>]]</span>, na.rm = <span style='color: #0000BB;'>TRUE</span><span style='color: #BBBB00;'>)</span> <span style='color: #00BB00;'>&gt;</span> <span style='color: #0000BB;'>0</span> <span style='color: #555555; font-style: italic;'># all positive</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below range assertions if needed:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data[["mpg"]], na.rm = TRUE) &lt;= 33.9</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># 10.4 &lt;= min(data[["mpg"]], na.rm = TRUE)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below deviance assertions if needed.</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># The mean is 20.09 and the standard deviation is 6.03:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data[["mpg"]], na.rm = TRUE) &lt;= 20.09 + 4 * 6.03</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># 20.09 - 4 * 6.03 &lt;= max(data[["mpg"]], na.rm = TRUE)</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>&#125;</span><span style='color: #0000BB;'>)</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>invisible</span><span style='color: #0000BB;'>(TRUE)</span></span>
<span class='c'>#&gt; <span style='color: #BBBB00;'>&#125;</span></span></code></pre>

</div>

It's pretty comprehensive! And the comments explain what's going on. I can take this function, modify it, and use it to check any new `mtcars`-like data.

If any assertion is violated, an error is raised with the offending line of code. If everything checks out then `TRUE` is returned invisibly. There is a downside here, in that when a single assertion fails the function will not check the rest.

In the above example I only checked the `wt` and `mpg` columns. When I'm validating data I often care about only a few columns. The `exemplar` function supports `tidyselect`, just like `dplyr`. All of the following will work:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nv'>mtcars</span>, <span class='nv'>wt</span>, <span class='nv'>mpg</span><span class='o'>)</span>
<span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nv'>mtcars</span>, <span class='o'>-</span><span class='nv'>cyl</span><span class='o'>)</span>
<span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nv'>mtcars</span>, <span class='nv'>vs</span><span class='o'>:</span><span class='nv'>carb</span><span class='o'>)</span>
<span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nv'>mtcars</span>, <span class='nf'><a href='https://tidyselect.r-lib.org/reference/all_of.html'>any_of</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"qsec"</span>, <span class='s'>"notacolumn"</span><span class='o'>)</span><span class='o'>)</span><span class='o'>)</span>
<span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nv'>mtcars</span>, <span class='nf'><a href='https://tidyselect.r-lib.org/reference/starts_with.html'>starts_with</a></span><span class='o'>(</span><span class='s'>"d"</span><span class='o'>)</span><span class='o'>)</span></code></pre>

</div>

The `exemplar` package also generates validation functions for individual vectors:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nv'>mtcars</span><span class='o'>$</span><span class='nv'>wt</span><span class='o'>)</span>
<span class='c'>#&gt; validate_mtcars_wt <span style='color: #00BB00;'>&lt;-</span> <span style='color: #BB0000;'>function</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span> <span style='color: #BBBB00;'>&#123;</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>stopifnot</span><span style='color: #0000BB;'>(</span>exprs = <span style='color: #00BBBB;'>&#123;</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>is.double</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #00BB00;'>!</span><span style='color: #00BBBB;'>any</span><span style='color: #BBBB00;'>(</span><span style='color: #00BBBB;'>is.na</span><span style='color: #0000BB;'>(</span>data<span style='color: #0000BB;'>)</span> <span style='color: #00BB00;'>|</span> <span style='color: #00BBBB;'>is.null</span><span style='color: #0000BB;'>(</span>data<span style='color: #0000BB;'>)</span><span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># Duplicate values were detected so this assertion has been disabled:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># !any(duplicated(data))</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>min</span><span style='color: #BBBB00;'>(</span>data, na.rm = <span style='color: #0000BB;'>TRUE</span><span style='color: #BBBB00;'>)</span> <span style='color: #00BB00;'>&gt;</span> <span style='color: #0000BB;'>0</span> <span style='color: #555555; font-style: italic;'># all positive</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below range assertions if needed:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data, na.rm = TRUE) &lt;= 5.424</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># 1.513 &lt;= min(data, na.rm = TRUE)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below deviance assertions if needed.</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># The mean is 3.22 and the standard deviation is 0.98:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data, na.rm = TRUE) &lt;= 3.22 + 4 * 0.98</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># 3.22 - 4 * 0.98 &lt;= max(data, na.rm = TRUE)</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>&#125;</span><span style='color: #0000BB;'>)</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>invisible</span><span style='color: #0000BB;'>(TRUE)</span></span>
<span class='c'>#&gt; <span style='color: #BBBB00;'>&#125;</span></span></code></pre>

</div>

Note how the validation function is named after the input. The function name can be specified with the `.function_suffix` parameter:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/exemplar/man/exemplar.html'>exemplar</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/stats/Uniform.html'>runif</a></span><span class='o'>(</span><span class='m'>100</span>, <span class='o'>-</span><span class='m'>10</span>, <span class='m'>10</span><span class='o'>)</span>, .function_suffix <span class='o'>=</span> <span class='s'>"random_numbers"</span><span class='o'>)</span>
<span class='c'>#&gt; validate_random_numbers <span style='color: #00BB00;'>&lt;-</span> <span style='color: #BB0000;'>function</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span> <span style='color: #BBBB00;'>&#123;</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>stopifnot</span><span style='color: #0000BB;'>(</span>exprs = <span style='color: #00BBBB;'>&#123;</span></span>
<span class='c'>#&gt;     <span style='color: #00BBBB;'>is.double</span><span style='color: #BBBB00;'>(</span>data<span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #00BB00;'>!</span><span style='color: #00BBBB;'>any</span><span style='color: #BBBB00;'>(</span><span style='color: #00BBBB;'>is.na</span><span style='color: #0000BB;'>(</span>data<span style='color: #0000BB;'>)</span> <span style='color: #00BB00;'>|</span> <span style='color: #00BBBB;'>is.null</span><span style='color: #0000BB;'>(</span>data<span style='color: #0000BB;'>)</span><span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #00BB00;'>!</span><span style='color: #00BBBB;'>any</span><span style='color: #BBBB00;'>(</span><span style='color: #00BBBB;'>duplicated</span><span style='color: #0000BB;'>(</span>data<span style='color: #0000BB;'>)</span><span style='color: #BBBB00;'>)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below range assertions if needed:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data, na.rm = TRUE) &lt;= 9.95231169741601</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># -9.70273485872895 &lt;= min(data, na.rm = TRUE)</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># (Un)comment or modify the below deviance assertions if needed.</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># The mean is 0.59 and the standard deviation is 5.8:</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># max(data, na.rm = TRUE) &lt;= 0.59 + 4 * 5.8</span></span>
<span class='c'>#&gt;     <span style='color: #555555; font-style: italic;'># 0.59 - 4 * 5.8 &lt;= max(data, na.rm = TRUE)</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>&#125;</span><span style='color: #0000BB;'>)</span></span>
<span class='c'>#&gt;   <span style='color: #00BBBB;'>invisible</span><span style='color: #0000BB;'>(TRUE)</span></span>
<span class='c'>#&gt; <span style='color: #BBBB00;'>&#125;</span></span></code></pre>

</div>

## What's validated?

The intention is that users will take these validations as a starting point and make adjustments as needed. Some assertions will be commented out by default, with a comment explaining why.

For a vector:

-   the data type is first checked
-   assertions for no missing or duplicate values are included, but if the input data violates these assertions then the statements will be commented out with an explanation
-   parity is checked. If the input is all positive, non-negative, negative, or non-positive, then an assertion for this will be included.
-   range assertions and deviance assertions (based on number of standard deviations from the mean, based on the input) are included, but commented out by default.

Alternatively, range assertions can be enabled with the `.enable_range_assertions` argument and deviance assertions with `.enable_deviance_assertions`. By default the `.allowed_deviance` is 4, that is, new data can be within 4 standard deviations of the mean, based on the statistics of the exemplar. This too can be adjusted.

Assertions for a data frame will include assertions for all of the selected columns, and will also check that those columns are present. There is also a validation that those columns are the *only* columns present, but this will be disabled if `exemplar` is asked to create an `exemplar` on a selection of columns in the data frame.

## How is this different to other data validation packages?

If I have a clear idea of what to validate in a data frame, then I'll just write the assertions using `assertthat`. If those assertions are complicated then I'll use a package like `assertr`.

The `exemplar` package doesn't provide any additional tools for validating data. In fact, it's deliberately restricted to base R (≥ 3.5) to ensure that the generated functions don't require any installed packages.

What `exemplar` does do is generate the validation functions automatically, based on an ideal output. This could be useful for, say, machine learning. Perhaps an `exemplar` is generated on training data and is used to validate test data, or any new data that needs to be scored.

------------------------------------------------------------------------

[The image at the top of this page is by Tima Miroshnichenko](https://www.pexels.com/photo/black-magnifying-glass-beside-yellow-pencil-6615076/) and is used under the terms of [the Pexels License](https://www.pexels.com/license/).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://r-lib.github.io/sessioninfo/reference/session_info.html'>session_info</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>─ Session info ───────────────────────────────────────────────────────────────</span></span>
<span class='c'>#&gt;  <span style='color: #555555; font-style: italic;'>setting </span> <span style='color: #555555; font-style: italic;'>value</span></span>
<span class='c'>#&gt;  version  R version 4.1.0 (2021-05-18)</span>
<span class='c'>#&gt;  os       macOS Big Sur 11.3</span>
<span class='c'>#&gt;  system   aarch64, darwin20</span>
<span class='c'>#&gt;  ui       X11</span>
<span class='c'>#&gt;  language (EN)</span>
<span class='c'>#&gt;  collate  en_AU.UTF-8</span>
<span class='c'>#&gt;  ctype    en_AU.UTF-8</span>
<span class='c'>#&gt;  tz       Australia/Melbourne</span>
<span class='c'>#&gt;  date     2022-03-20</span>
<span class='c'>#&gt;  pandoc   2.11.4 @ /Applications/RStudio.app/Contents/MacOS/pandoc/ (via rmarkdown)</span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>─ Packages ───────────────────────────────────────────────────────────────────</span></span>
<span class='c'>#&gt;  <span style='color: #555555; font-style: italic;'>package    </span> <span style='color: #555555; font-style: italic;'>*</span> <span style='color: #555555; font-style: italic;'>version   </span> <span style='color: #555555; font-style: italic;'>date (UTC)</span> <span style='color: #555555; font-style: italic;'>lib</span> <span style='color: #555555; font-style: italic;'>source</span></span>
<span class='c'>#&gt;  backports     1.4.1      <span style='color: #555555;'>2021-12-13</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  brio          1.1.3      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  cachem        1.0.6      <span style='color: #555555;'>2021-08-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  callr         3.7.0      <span style='color: #555555;'>2021-04-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  cli           3.2.0      <span style='color: #555555;'>2022-02-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  crayon        1.5.0      <span style='color: #555555;'>2022-02-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  desc          1.4.0      <span style='color: #555555;'>2021-09-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  devtools      2.4.3      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  digest        0.6.29     <span style='color: #555555;'>2021-12-01</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  downlit       0.4.0      <span style='color: #555555;'>2021-10-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  ellipsis      0.3.2      <span style='color: #555555;'>2021-04-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  evaluate      0.14       <span style='color: #555555;'>2019-05-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  exemplar    * <span style='color: #BB00BB; font-weight: bold;'>0.0.0.9000</span> <span style='color: #555555;'>2022-03-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #BB00BB; font-weight: bold;'>Github (mdneuzerling/exemplar@19b310b)</span></span>
<span class='c'>#&gt;  fansi         1.0.2      <span style='color: #555555;'>2022-01-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  fastmap       1.1.0      <span style='color: #555555;'>2021-01-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  fs            1.5.2      <span style='color: #555555;'>2021-12-08</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  glue          1.6.2      <span style='color: #555555;'>2022-02-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  htmltools     0.5.2      <span style='color: #555555;'>2021-08-25</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  hugodown      <span style='color: #BB00BB; font-weight: bold;'>0.0.0.9000</span> <span style='color: #555555;'>2021-09-18</span> <span style='color: #555555;'>[1]</span> <span style='color: #BB00BB; font-weight: bold;'>Github (r-lib/hugodown@168a361)</span></span>
<span class='c'>#&gt;  knitr         1.37       <span style='color: #555555;'>2021-12-16</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  lifecycle     1.0.1      <span style='color: #555555;'>2021-09-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  magrittr      2.0.2      <span style='color: #555555;'>2022-01-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  memoise       2.0.1      <span style='color: #555555;'>2021-11-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  pillar        1.7.0      <span style='color: #555555;'>2022-02-01</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  pkgbuild      1.3.1      <span style='color: #555555;'>2021-12-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  pkgconfig     2.0.3      <span style='color: #555555;'>2019-09-22</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  pkgload       1.2.4      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  prettycode    1.1.0      <span style='color: #555555;'>2019-12-16</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  prettyunits   1.1.1      <span style='color: #555555;'>2020-01-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  processx      3.5.2      <span style='color: #555555;'>2021-04-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  ps            1.6.0      <span style='color: #555555;'>2021-02-28</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  purrr         0.3.4      <span style='color: #555555;'>2020-04-17</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  R.cache       0.15.0     <span style='color: #555555;'>2021-04-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  R.methodsS3   1.8.1      <span style='color: #555555;'>2020-08-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  R.oo          1.24.0     <span style='color: #555555;'>2020-08-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  R.utils       2.11.0     <span style='color: #555555;'>2021-09-26</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  R6            2.5.1      <span style='color: #555555;'>2021-08-19</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rematch2      2.1.2      <span style='color: #555555;'>2020-05-01</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  remotes       2.4.2      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rlang         1.0.1      <span style='color: #555555;'>2022-02-03</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rmarkdown     2.11       <span style='color: #555555;'>2021-09-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  rprojroot     2.0.2      <span style='color: #555555;'>2020-11-15</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  rstudioapi    0.13       <span style='color: #555555;'>2020-11-12</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  sessioninfo   1.2.2      <span style='color: #555555;'>2021-12-06</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  stringi       1.7.6      <span style='color: #555555;'>2021-11-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  stringr       1.4.0      <span style='color: #555555;'>2019-02-10</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  styler        1.6.2      <span style='color: #555555;'>2021-09-23</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  testthat      3.1.2      <span style='color: #555555;'>2022-01-20</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  tibble        3.1.6      <span style='color: #555555;'>2021-11-07</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  tidyselect  * 1.1.2      <span style='color: #555555;'>2022-02-21</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  usethis       2.1.5      <span style='color: #555555;'>2021-12-09</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  utf8          1.2.2      <span style='color: #555555;'>2021-07-24</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  vctrs         0.3.8      <span style='color: #555555;'>2021-04-29</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt;  withr         2.4.3      <span style='color: #555555;'>2021-11-30</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  xfun          0.29       <span style='color: #555555;'>2021-12-14</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.1)</span></span>
<span class='c'>#&gt;  yaml          2.2.1      <span style='color: #555555;'>2020-02-01</span> <span style='color: #555555;'>[1]</span> <span style='color: #555555;'>CRAN (R 4.1.0)</span></span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; <span style='color: #555555;'> [1] /Library/Frameworks/R.framework/Versions/4.1-arm64/Resources/library</span></span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; <span style='color: #00BBBB; font-weight: bold;'>──────────────────────────────────────────────────────────────────────────────</span></span></code></pre>

</div>

