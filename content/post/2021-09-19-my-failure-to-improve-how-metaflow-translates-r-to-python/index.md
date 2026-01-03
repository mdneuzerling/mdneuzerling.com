---
title: "I Tried to Improve how Metaflow Converts R to Python (and I Failed)"
author: ~
date: '2021-09-19'
slug: i-tried-to-improve-how-metaflow-converts-r-to-python-and-i-failed
category: code
tags:
    - R
    - python
    - metaflow
featured: "/img/featured/brick-wall.webp"
output: hugodown::md_document
rmd_hash: ee64103bbd3293a7

---

[Metaflow is one of my favourite R packages](/post/using-metaflow-to-make-model-tuning-less-painful/). Actually, it's a Python module, but the R package provides a set of bindings for running R code through Metaflow. Recently I've spent a good amount of effort trying to improve the way that R data is translated to the Python side of Metaflow, but I just can't get it to work.

So I thought I'd post about what I've learnt. Maybe someone will have an answer. Or maybe just writing out the problem will be enough to give me more ideas. Or maybe it will just be therapeutic!

## How R and Python talk to each other

I work on a team that's a mixture of Python and R specialists.

Okay, mostly Python.

Actually, I'm the only R user.

I'm confident enough with my Python skills, but R feels like *home*. So reticulate is pretty important for me as it lets me access all of the benefits of Python while staying within R.

Reticulate embeds a Python session within an R session, and through a special module makes R objects available in Python. [It also converts between R types and Python types](https://rstudio.github.io/reticulate/articles/calling_python.html#type-conversions-1). This is where it gets a bit tricky.

For the most part, R objects and Python objects are interchangeable. Integers are integers, and strings are strings. Base Python doesn't have a concept of a data frame or an array, so reticulate converts to the pandas and numpy constructs, respectively.

But it doesn't work all of the time. Reticulate is really good, but R and Python aren't always going to be compatible. A good example is the way that missing values are converted. In Python, numpy's `NaN` is often used for missing values. Whereas R supports a few types of missing values, numpy's `NaN` is only ever a float. So the conversions can go a bit astray:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>reticulate</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/reticulate/man/r-py-conversion.html'>r_to_py</a></span><span class='o'>(</span><span class='kc'>NA_real_</span><span class='o'>)</span>
<span class='c'>#&gt; nan</span>
<span class='nf'>reticulate</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/reticulate/man/r-py-conversion.html'>r_to_py</a></span><span class='o'>(</span><span class='kc'>NA_complex_</span><span class='o'>)</span>
<span class='c'>#&gt; (nan+nanj)</span>
<span class='nf'>reticulate</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/reticulate/man/r-py-conversion.html'>r_to_py</a></span><span class='o'>(</span><span class='kc'>NA_integer_</span><span class='o'>)</span>
<span class='c'>#&gt; -2147483648</span>
<span class='nf'>reticulate</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/reticulate/man/r-py-conversion.html'>r_to_py</a></span><span class='o'>(</span><span class='kc'>NA</span><span class='o'>)</span>
<span class='c'>#&gt; True</span></code></pre>

</div>

That last one is especially concerning, since defaulting missing Boolean values to true could cause silent errors. Reticulate isn't doing anything wrong here, since that behaviour is expected in Python. In R, `NA` is of logical type (hence why there's no `NA_logical_`). And in Python, missing values become `True` when converted to Booleans:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>import numpy as np
bool(np.NaN)
#> True</code></pre>

</div>

For the most part, converting R objects to Python work pretty well, but there are certainly some concerning edge cases. And since Metaflow is fundamentally a Python module, these conversion mishaps are important.

## Metaflow's serialisation

When defining a step in a Metaflow *flow*, if I want to store a value `x` as `3` I might do something like this:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/step.html'>step</a></span><span class='o'>(</span>step <span class='o'>=</span> <span class='s'>"start"</span>,
     r_function <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>self</span><span class='o'>)</span> <span class='o'>&#123;</span>
       <span class='nv'>self</span><span class='o'>$</span><span class='nv'>x</span> <span class='o'>&lt;-</span> <span class='m'>3</span>
     <span class='o'>&#125;</span>,
     next_step <span class='o'>=</span> <span class='s'>"end"</span><span class='o'>)</span></code></pre>

</div>

Metaflow does something clever under the hood. In R, that act of assigning a value with a combination of [`$`](https://rdrr.io/r/base/Extract.html) and [`<-`](https://rdrr.io/r/base/assignOps.html) is a *generic function*. I can take a look at all of the available *methods* associated with that function:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/utils/methods.html'>methods</a></span><span class='o'>(</span><span class='nv'>`$&lt;-`</span><span class='o'>)</span>
<span class='c'>#&gt;  [1] $&lt;-,data.frame-method           $&lt;-,envRefClass-method         </span>
<span class='c'>#&gt;  [3] $&lt;-,localRefClass-method        $&lt;-,refObjectGenerator-method  </span>
<span class='c'>#&gt;  [5] $&lt;-.bibentry*                   $&lt;-.data.frame                 </span>
<span class='c'>#&gt;  [7] $&lt;-.grouped_df*                 $&lt;-.metaflow.flowspec.FlowSpec*</span>
<span class='c'>#&gt;  [9] $&lt;-.person*                     $&lt;-.python.builtin.dict*       </span>
<span class='c'>#&gt; [11] $&lt;-.python.builtin.object*      $&lt;-.quosures*                  </span>
<span class='c'>#&gt; [13] $&lt;-.rlang_ctxt_pronoun*         $&lt;-.rlang_data_pronoun*        </span>
<span class='c'>#&gt; [15] $&lt;-.tbl_df*                     $&lt;-.vctrs_list_of*             </span>
<span class='c'>#&gt; [17] $&lt;-.vctrs_rcrd*                 $&lt;-.vctrs_sclr*                </span>
<span class='c'>#&gt; [19] $&lt;-.vctrs_vctr*                </span>
<span class='c'>#&gt; see '?methods' for accessing help and source code</span></code></pre>

</div>

Sure enough, `$<-.metaflow.flowspec.FlowSpec` is one such method. There's a similar method for `[[<-`, which would be used if I had instead written `self[["x"]] <- 3`. And for retrieving those values, there are methods for [`$`](https://rdrr.io/r/base/Extract.html) and [`[[`](https://rdrr.io/r/base/Extract.html).

Metaflow uses these methods to *serialize* the data before it's assigned to the value, and *deserialize* the data before it's retrieved. It uses two functions --- `mf_serialize` and `mf_deserialize` --- to do this.

Metaflow's serialization function uses base R's `serialize` function for turning objects into their raw bytes. But some objects, which it calls "simple objects", go through without interference.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>simple_type</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>obj</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/is.recursive.html'>is.atomic</a></span><span class='o'>(</span><span class='nv'>obj</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='kc'>TRUE</span><span class='o'>)</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/list.html'>is.list</a></span><span class='o'>(</span><span class='nv'>obj</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'>if</span> <span class='o'>(</span><span class='s'>"data.table"</span> <span class='o'>%in%</span> <span class='nf'><a href='https://rdrr.io/r/base/class.html'>class</a></span><span class='o'>(</span><span class='nv'>obj</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='kc'>FALSE</span><span class='o'>)</span>
    <span class='o'>&#125;</span>

    <span class='kr'>for</span> <span class='o'>(</span><span class='nv'>item</span> <span class='kr'>in</span> <span class='nv'>obj</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='kr'>if</span> <span class='o'>(</span><span class='o'>!</span><span class='nf'>simple_type</span><span class='o'>(</span><span class='nv'>item</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
        <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='kc'>FALSE</span><span class='o'>)</span>
      <span class='o'>&#125;</span>
    <span class='o'>&#125;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='kc'>TRUE</span><span class='o'>)</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='kc'>FALSE</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
<span class='o'>&#125;</span></code></pre>

</div>

A value like `3` or a data frame like `mtcars` would be considered a simple type and would be left unchanged by `mf_serialize`. A function is not a simple type and so it would get be serialized. The second argument in base R's `serialize` function would usually be a connection to which the raw bytes would be sent, but the `NULL` value makes the function return those bytes instead:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>mf_serialize</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'>simple_type</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>serialize</a></span><span class='o'>(</span><span class='nv'>object</span>, <span class='kc'>NULL</span><span class='o'>)</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
<span class='o'>&#125;</span></code></pre>

</div>

The `mf_deserialize` function acts in reverse, attempting to convert raw bytes if possible, and letting other objects pass through unaffected:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>mf_deserialize</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>r_obj</span> <span class='o'>&lt;-</span> <span class='nv'>object</span>

  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/raw.html'>is.raw</a></span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='c'># for bytearray try to unserialize</span>
    <span class='kr'><a href='https://rdrr.io/r/base/conditions.html'>tryCatch</a></span><span class='o'>(</span>
      <span class='o'>&#123;</span>
        <span class='nv'>r_obj</span> <span class='o'>&lt;-</span> <span class='nv'>object</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>unserialize</a></span><span class='o'>(</span><span class='o'>)</span>
      <span class='o'>&#125;</span>,
      error <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>e</span><span class='o'>)</span> <span class='o'>&#123;</span>
        <span class='nv'>r_obj</span> <span class='o'>&lt;-</span> <span class='nv'>object</span>
      <span class='o'>&#125;</span>
    <span class='o'>)</span>
  <span class='o'>&#125;</span>
  
  <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='nv'>r_obj</span><span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

The pattern for Metaflow is that an R object is serialized with `mf_serialize` and then converted to Python with `reticulate`, although for objects of "simple type" this "serialization" does nothing. When the value is retrieved it is converted back to R and then passed through `mf_deserialize`.

This behaviour was strange to me at first. Why not convert everything to raw bytes? Or nothing? It would later make sense, but I needed to run into some errors before I could understand. For now I wanted to understand what would happen if I changed the `mf_serialize` function.

## Invertible R objects

What I would hope is that the following holds true for all `x`:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>x</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/mf_serialize.html'>mf_serialize</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'>%&gt;%</span> <span class='nv'>r_to_py</span> <span class='o'>%&gt;%</span> <span class='nv'>py_to_r</span> <span class='o'>%&gt;%</span> <span class='nv'>mf_deserialize</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/r/base/identical.html'>identical</a></span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span></code></pre>

</div>

That is, an object should not be changed when it is serialized, converted to Python, converted back to R, and deserialized.

That impact of this is that if I save some data to the `self` object and then later retrieve it, perhaps in a different step, then the data will be unchanged. This is important: if my data changes in subtle ways without my knowledge, then I could run into all sorts of problems, and those problems could be very quiet.

To investigate this, I use the below function. For given `serialize` and `deserialize` functions, this checks if `x` comes through the above pipe unscathed. That is, it checks if `x` is *invertible* under `serialize` and `deserialize`. Values that can't be converted to Python after serialization become `NA`:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>is_invertible</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span>, <span class='nv'>serialize</span>, <span class='nv'>deserialize</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>as_python</span> <span class='o'>=</span> <span class='kr'><a href='https://rdrr.io/r/base/conditions.html'>tryCatch</a></span><span class='o'>(</span>
    <span class='nv'>x</span> <span class='o'>%&gt;%</span> <span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>serialize</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'>%&gt;%</span> <span class='nf'>reticulate</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/reticulate/man/r-py-conversion.html'>r_to_py</a></span><span class='o'>(</span><span class='o'>)</span>,
    error <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>e</span><span class='o'>)</span> <span class='kc'>NA</span>
  <span class='o'>)</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/identical.html'>identical</a></span><span class='o'>(</span><span class='nv'>as_python</span>, <span class='kc'>NA</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='kc'>NA</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
  <span class='nf'><a href='https://rdrr.io/r/base/identical.html'>identical</a></span><span class='o'>(</span><span class='nv'>x</span>, <span class='nv'>as_python</span> <span class='o'>%&gt;%</span> <span class='nf'>reticulate</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/reticulate/man/r-py-conversion.html'>py_to_r</a></span><span class='o'>(</span><span class='o'>)</span> <span class='o'>%&gt;%</span> <span class='nf'>deserialize</span><span class='o'>(</span><span class='o'>)</span><span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

To test invertibility of candidate serialization functions, I put down examples for as many different types of R objects as I can think of in a named list I call `candidates`:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>candidates</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>
  `5` <span class='o'>=</span> <span class='m'>5</span>, `5.5` <span class='o'>=</span> <span class='m'>5.5</span>, `5L` <span class='o'>=</span> <span class='m'>5L</span>, `letter` <span class='o'>=</span> <span class='s'>"a"</span>, `many letters` <span class='o'>=</span> <span class='s'>"character"</span>,
  `TRUE` <span class='o'>=</span> <span class='kc'>TRUE</span>, `FALSE` <span class='o'>=</span> <span class='kc'>FALSE</span>, `NULL` <span class='o'>=</span> <span class='kc'>NULL</span>, `NaN` <span class='o'>=</span> <span class='kc'>NaN</span>,
  `Inf` <span class='o'>=</span> <span class='kc'>Inf</span>, `-Inf` <span class='o'>=</span> <span class='o'>-</span><span class='kc'>Inf</span>, `NA_character_` <span class='o'>=</span> <span class='kc'>NA_character_</span>, `NA` <span class='o'>=</span> <span class='kc'>NA</span>,
  `NA_integer_` <span class='o'>=</span> <span class='kc'>NA_integer_</span>, `NA_complex_` <span class='o'>=</span> <span class='kc'>NA_complex_</span>,
  `NA_real_` <span class='o'>=</span> <span class='kc'>NA_real_</span>, `date` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/Sys.time.html'>Sys.Date</a></span><span class='o'>(</span><span class='o'>)</span>, `time` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/Sys.time.html'>Sys.time</a></span><span class='o'>(</span><span class='o'>)</span>,
  `data.frame` <span class='o'>=</span> <span class='nv'>mtcars</span>, `tibble` <span class='o'>=</span> <span class='nf'>tibble</span><span class='nf'>::</span><span class='nf'><a href='https://tibble.tidyverse.org/reference/as_tibble.html'>as_tibble</a></span><span class='o'>(</span><span class='nv'>mtcars</span><span class='o'>)</span>,
  `data.table` <span class='o'>=</span> <span class='nf'>data.table</span><span class='nf'>::</span><span class='nf'><a href='https://Rdatatable.gitlab.io/data.table/reference/as.data.table.html'>as.data.table</a></span><span class='o'>(</span><span class='nv'>mtcars</span><span class='o'>)</span>,
  `integer vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='m'>1L</span>, <span class='m'>2L</span>, <span class='m'>3L</span><span class='o'>)</span>, `double vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='m'>1.5</span>, <span class='m'>2.5</span>, <span class='m'>3.5</span><span class='o'>)</span>,
  `character vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"a"</span>, <span class='s'>"b"</span>, <span class='s'>"c"</span><span class='o'>)</span>,
  `logical vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='kc'>TRUE</span>, <span class='kc'>FALSE</span>, <span class='kc'>TRUE</span><span class='o'>)</span>,
  `empty integer vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/integer.html'>integer</a></span><span class='o'>(</span><span class='o'>)</span>, `empty numeric vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/numeric.html'>numeric</a></span><span class='o'>(</span><span class='o'>)</span>,
  `empty character vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/character.html'>character</a></span><span class='o'>(</span><span class='o'>)</span>, `empty logical vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/logical.html'>logical</a></span><span class='o'>(</span><span class='o'>)</span>,
  `empty list` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='o'>)</span>, `unnamed singleton list` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='s'>"red panda"</span><span class='o'>)</span>,
  `unnamed list` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='s'>"red panda"</span>, <span class='m'>5</span><span class='o'>)</span>,
  `named singleton list` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>animal <span class='o'>=</span> <span class='s'>"red panda"</span><span class='o'>)</span>,
  `named list` <span class='o'>=</span><span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>animal <span class='o'>=</span> <span class='s'>"red panda"</span>, number <span class='o'>=</span> <span class='m'>5</span><span class='o'>)</span>,
  `raw vector` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/raw.html'>as.raw</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='m'>1</span><span class='o'>:</span><span class='m'>10</span><span class='o'>)</span><span class='o'>)</span>,
  `function` <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='nv'>x</span> <span class='o'>+</span> <span class='m'>1</span>,
  `matrix` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/matrix.html'>matrix</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='m'>1</span>,<span class='m'>2</span>,<span class='m'>3</span>,<span class='m'>4</span><span class='o'>)</span>, nrow <span class='o'>=</span> <span class='m'>2</span>, ncol <span class='o'>=</span> <span class='m'>2</span><span class='o'>)</span>,
  `formula` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/stats/formula.html'>as.formula</a></span><span class='o'>(</span><span class='nv'>y</span> <span class='o'>~</span> <span class='nv'>x</span><span class='o'>)</span>,
  `factor` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/factor.html'>factor</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"a"</span>, <span class='s'>"b"</span>, <span class='s'>"c"</span><span class='o'>)</span><span class='o'>)</span>,
  `global environment` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/environment.html'>globalenv</a></span><span class='o'>(</span><span class='o'>)</span>,
  `empty environment` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/environment.html'>emptyenv</a></span><span class='o'>(</span><span class='o'>)</span>,
  `custom class` <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/structure.html'>structure</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='m'>1</span>, <span class='m'>2</span>, <span class='m'>3</span><span class='o'>)</span>, class <span class='o'>=</span> <span class='s'>"custom"</span><span class='o'>)</span>
<span class='o'>)</span></code></pre>

</div>

As an aside, these candidates make for great test cases.

Now I can test three different pairs of serialisation functions:

-   `serialize nothing`, in which `serialize = deserialize = identity`. This tests how invertible objects are as is under Python.
-   `metaflow serialization` using `mf_serialize` and `mf_deserialize`, in which objects of "simple type" go through as is but the rest are serialized to bytes.
-   `serialize everything`, which is like `metaflow serialization` except without the exception for objects of "simple type".

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>tibble_of_invertibility</span> <span class='o'>&lt;-</span> <span class='nf'>tibble</span><span class='nf'>::</span><span class='nf'><a href='https://tibble.tidyverse.org/reference/tibble.html'>tibble</a></span><span class='o'>(</span>
  candidate <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='o'>(</span><span class='nv'>candidates</span><span class='o'>)</span>,
  `serialize nothing` <span class='o'>=</span> <span class='nf'>purrr</span><span class='nf'>::</span><span class='nf'><a href='https://purrr.tidyverse.org/reference/map.html'>map_lgl</a></span><span class='o'>(</span>
    <span class='nv'>candidates</span>, <span class='nv'>is_invertible</span>,
    serialize <span class='o'>=</span> <span class='nv'>identity</span>, deserialize <span class='o'>=</span> <span class='nv'>identity</span>
  <span class='o'>)</span>,
  `metaflow serialization` <span class='o'>=</span> <span class='nf'>purrr</span><span class='nf'>::</span><span class='nf'><a href='https://purrr.tidyverse.org/reference/map.html'>map_lgl</a></span><span class='o'>(</span>
    <span class='nv'>candidates</span>, <span class='nv'>is_invertible</span>,
    serialize <span class='o'>=</span> <span class='nv'>mf_serialize</span>, deserialize <span class='o'>=</span> <span class='nv'>mf_deserialize</span>
  <span class='o'>)</span>,
  `serialize everything` <span class='o'>=</span> <span class='nf'>purrr</span><span class='nf'>::</span><span class='nf'><a href='https://purrr.tidyverse.org/reference/map.html'>map_lgl</a></span><span class='o'>(</span>
    <span class='nv'>candidates</span>, <span class='nv'>is_invertible</span>,
    serialize <span class='o'>=</span> \<span class='o'>(</span><span class='nv'>x</span><span class='o'>)</span> <span class='nf'>base</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>serialize</a></span><span class='o'>(</span><span class='nv'>x</span>, <span class='kc'>NULL</span><span class='o'>)</span>, deserialize <span class='o'>=</span> <span class='nf'>base</span><span class='nf'>::</span><span class='nv'><a href='https://rdrr.io/r/base/serialize.html'>unserialize</a></span>
  <span class='o'>)</span>
<span class='o'>)</span>
<span class='c'>#&gt; y ~ x</span>
<span class='c'>#&gt; &lt;environment: R_GlobalEnv&gt;</span>
<span class='c'>#&gt; &lt;environment: R_EmptyEnv&gt;</span>
<span class='nv'>tibble_of_invertibility</span> <span class='o'>%&gt;%</span> 
  <span class='nf'><a href='https://dplyr.tidyverse.org/reference/mutate_all.html'>mutate_if</a></span><span class='o'>(</span><span class='nv'>is.logical</span>, <span class='o'>~</span><span class='nf'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='o'>(</span><span class='nv'>.x</span>, <span class='s'>"\U00002705"</span>, <span class='s'>"\U0000274C"</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>%&gt;%</span> 
  <span class='nf'>knitr</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/knitr/man/kable.html'>kable</a></span><span class='o'>(</span>align <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"l"</span>, <span class='s'>"c"</span>, <span class='s'>"c"</span>, <span class='s'>"c"</span><span class='o'>)</span><span class='o'>)</span> 
</code></pre>

| candidate              | serialize nothing | metaflow serialization | serialize everything |
|:-----------------------|:-----------------:|:----------------------:|:--------------------:|
| 5                      |         ✅         |           ✅            |          ✅           |
| 5.5                    |         ✅         |           ✅            |          ✅           |
| 5L                     |         ✅         |           ✅            |          ✅           |
| letter                 |         ✅         |           ✅            |          ✅           |
| many letters           |         ✅         |           ✅            |          ✅           |
| TRUE                   |         ✅         |           ✅            |          ✅           |
| FALSE                  |         ✅         |           ✅            |          ✅           |
| NULL                   |         ✅         |           ✅            |          ✅           |
| NaN                    |         ✅         |           ✅            |          ✅           |
| Inf                    |         ✅         |           ✅            |          ✅           |
| -Inf                   |         ✅         |           ✅            |          ✅           |
| NA_character\_         |         ❌         |           ❌            |          ✅           |
| NA                     |         ❌         |           ❌            |          ✅           |
| NA_integer\_           |         ✅         |           ✅            |          ✅           |
| NA_complex\_           |         ✅         |           ✅            |          ✅           |
| NA_real\_              |         ✅         |           ✅            |          ✅           |
| date                   |         ✅         |           ✅            |          ✅           |
| time                   |         ❌         |           ❌            |          ✅           |
| data.frame             |         ❌         |           ❌            |          ✅           |
| tibble                 |         ❌         |           ❌            |          ✅           |
| data.table             |         ❌         |           ❌            |          ❌           |
| integer vector         |         ✅         |           ✅            |          ✅           |
| double vector          |         ✅         |           ✅            |          ✅           |
| character vector       |         ✅         |           ✅            |          ✅           |
| logical vector         |         ✅         |           ✅            |          ✅           |
| empty integer vector   |         ❌         |           ❌            |          ✅           |
| empty numeric vector   |         ❌         |           ❌            |          ✅           |
| empty character vector |         ❌         |           ❌            |          ✅           |
| empty logical vector   |         ❌         |           ❌            |          ✅           |
| empty list             |         ✅         |           ✅            |          ✅           |
| unnamed singleton list |         ❌         |           ❌            |          ✅           |
| unnamed list           |         ✅         |           ✅            |          ✅           |
| named singleton list   |         ✅         |           ✅            |          ✅           |
| named list             |         ✅         |           ✅            |          ✅           |
| raw vector             |         ✅         |           ✅            |          ✅           |
| function               |         ❌         |           ✅            |          ✅           |
| matrix                 |         ✅         |           ✅            |          ✅           |
| formula                |        NA         |           ✅            |          ✅           |
| factor                 |         ❌         |           ❌            |          ✅           |
| global environment     |        NA         |           ✅            |          ✅           |
| empty environment      |        NA         |           ✅            |          ✅           |
| custom class           |         ❌         |           ❌            |          ✅           |

</div>

It's no surprise that the more aggressive the serialization, the less that Python interferes. Raw vectors in R are translated to byte arrays in Python, so there's not much chance for interference.

A few notes here. Data tables are not technically invertible under the "serialize everything" approach because the pointer changes when translating back into R from Python. However, the value of the table is the same, so it's unlikely to be an issue.

Likewise, data frames and tibbles can come back from Python land with `pandas` indices, but their values are otherwise the same. So these could be argued as invertible under all of the options.

## 1st attempt: Redefine `mf_serialize`

It seems like, in order to minimise the interference that Python has with R data, I should redefine `mf_serialize` to be take the "serialize everything" approach:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>mf_serialize</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>serialize</a></span><span class='o'>(</span><span class='nv'>object</span>, <span class='kc'>NULL</span><span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

I don't have to touch `mf_deserialize` here; that function already attempts to `unserialize` raw vectors, and it will also preserve backwards compatibility with artifacts generated under the current version of Metaflow.

But then the integration tests throw the following error at me:

``` text
Metaflow 2.3.1 executing BasicForeachTestFlow for user:runner
Validating your flow...
    The graph looks good!
2021-07-26 07:08:17.181 Workflow starting (run-id 1627283297164120):
2021-07-26 07:08:17.189 [1627283297164120/start/1 (pid 14590)] Task is starting.
2021-07-26 07:08:20.701 [1627283297164120/start/1 (pid 14590)] Task finished successfully.
2021-07-26 07:08:20.709 [1627283297164120/foreach_split/2 (pid 14704)] Task is starting.
2021-07-26 07:08:24.223 [1627283297164120/foreach_split/2 (pid 14704)] Foreach yields 133 child steps.
2021-07-26 07:08:24.223 [1627283297164120/foreach_split/2 (pid 14704)] Task finished successfully.
2021-07-26 07:08:24.225 Workflow failed.
2021-07-26 07:08:24.225 Terminating 0 active tasks...
2021-07-26 07:08:24.225 Flushing logs...
    Step failure:
    Step foreach_split (task-id 2) failed: Foreach in step foreach_split yielded 133 child steps which is more than the current maximum of 100 children. You can raise the maximum with the --max-num-splits option. 
```

Metaflow steps allow for a `foreach` argument, in which a subsequent step can be split up to be performed once for each value of a given variable. So for example, I could provide the value of [`c("a", "b", "c")`](https://rdrr.io/r/base/c.html) to `foreach`, and the next step will be split into three, with each taking on one of the three values.

Under the old `mf_serialize`, [`c("a", "b", "c")`](https://rdrr.io/r/base/c.html) is an object of "simple type" and so is directly converted by reticulate into a numpy array in Python, `["a", "b", "c"]`. Under my new `mf_serialize`, [`c("a", "b", "c")`](https://rdrr.io/r/base/c.html) is serialized to this:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>serialize</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='s'>"a"</span>, <span class='s'>"b"</span>, <span class='s'>"c"</span><span class='o'>)</span>, <span class='kc'>NULL</span><span class='o'>)</span>
<span class='c'>#&gt;  [1] 58 0a 00 00 00 03 00 04 01 00 00 03 05 00 00 00 00 05 55 54 46 2d 38 00 00</span>
<span class='c'>#&gt; [26] 00 10 00 00 00 03 00 04 00 09 00 00 00 01 61 00 04 00 09 00 00 00 01 62 00</span>
<span class='c'>#&gt; [51] 04 00 09 00 00 00 01 63</span></code></pre>

</div>

This is a raw vector of 58 bytes, which is converted by reticulate into a byte array of 58 bytes. When Metaflow attempts to split on this value, it generates 58 new steps. And instead of splitting on values like "a" or "b" or "c", the generated steps will split on individual, meaningless bytes.

The error above doesn't quite show this, but it does give a hint as to what's going on --- tests that previously passed are now generated so many splits that Metaflow is exceeding its configured limits.

Whoever coded up `mf_serialize` was obviously aware of this, and this is why they didn't go with the far-too-simple approach of serializing everything. Python needs to be able to understand at least some of the structure of the R objects so that it can appropriately split on values in `foreach` steps.

## 2nd attempt: Python classes

Python needs to understand *some* of the structure of R objects, but it doesn't need to understand everything. For example, Python needs to know that the serialized form of [`c("a", "b", "c")`](https://rdrr.io/r/base/c.html) is actually of length 3, but it doesn't need to know the contents of the vector (I hope!). Is it possible to trick Python into thinking that those 58 bytes are actually an object of length 3?

Python classes have *dunder* methods, so-called because they're surrounded by double underscores. These can be used to override the default behaviour of Python objects. So with a custom Python class I can define a `__getitem__` method which overrides the usual indexing behaviour with Python, like how Metaflow provides [`[[`](https://rdrr.io/r/base/Extract.html) and [`$`](https://rdrr.io/r/base/Extract.html) methods in R. I can also define a `__len__` method for overriding how length is calculated.

The idea is to create a wrapper around R objects to stop Python from trying to apply its own logic. I'll specify the length of the R object at initialisation, and define a custom `__getitem__` method that delays indexing the object until we're back in R-land. It's like I'm giving Python exactly as much information about R objects as it needs, and not a bit more.

I can define a Python class in R using reticulate. This Python class will store the serialized data representation of an R object and its pre-calculated length, and these will be left untouched in Python land.

It's important that the raw R data and length are calculated before being provided to the Python class. This is because if I were to perform that calculation within the Python class constructor then the R object would be converted to Python *before* serialization, defeating the purpose of the class.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>MetaflowRObject</span> <span class='o'>&lt;-</span> <span class='nf'>reticulate</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/reticulate/man/PyClass.html'>PyClass</a></span><span class='o'>(</span>
  <span class='s'>"MetaflowRObject"</span>,
  <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span>
    `__init__` <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>self</span>, <span class='nv'>data</span>, <span class='nv'>length</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='nv'>self</span><span class='o'>$</span><span class='nv'>data</span> <span class='o'>&lt;-</span> <span class='nv'>data</span>
      <span class='nv'>self</span><span class='o'>$</span><span class='nv'>length</span> <span class='o'>&lt;-</span> <span class='nv'>length</span>
      <span class='kc'>NULL</span>
    <span class='o'>&#125;</span>,
    `__len__` <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>self</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='nv'>self</span><span class='o'>$</span><span class='nv'>length</span>
    <span class='o'>&#125;</span>,
    `__eq__` <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>self</span>, <span class='nv'>other</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='nv'>self</span><span class='o'>$</span><span class='nv'>data</span> <span class='o'>==</span> <span class='nv'>other</span><span class='o'>$</span><span class='nv'>data</span>
    <span class='o'>&#125;</span>,
    `__getitem__` <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>self</span>, <span class='nv'>x</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/mf_serialize.html'>mf_serialize</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/mf_serialize.html'>mf_deserialize</a></span><span class='o'>(</span><span class='nv'>self</span><span class='o'>$</span><span class='nv'>data</span><span class='o'>)</span><span class='o'>[[</span><span class='nv'>x</span><span class='o'>+</span><span class='m'>1</span><span class='o'>]</span><span class='o'>]</span><span class='o'>)</span>
    <span class='o'>&#125;</span>
  <span class='o'>)</span>
<span class='o'>)</span></code></pre>

</div>

Note also the `__eq__` method, which lets Python determine if two R objects are the same by comparing their representative byte arrays.

The new `mf_serialize` function will look take any R object and return a Python object of class "MetaflowRObject":

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>mf_serialize</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nf'>MetaflowRObject</span><span class='o'>(</span>
    data <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>serialize</a></span><span class='o'>(</span><span class='nv'>object</span>, <span class='kc'>NULL</span><span class='o'>)</span>,
    length <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/length.html'>length</a></span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span>
  <span class='o'>)</span>
<span class='o'>&#125;</span></code></pre>

</div>

There's a similar `mf_deserialize` function here for converting back from these classes, but I'll skip it for now because this won't work anyway:

``` text
══ Failed tests ════════════════════════════════════════════════════════════════
── Error (test-serialization.R:3:3): serialize functions work properly ───────────────────────────
Error: Unable to access object (object is from previous session and is now invalid)
Backtrace:
    █
 1. └─metaflow:::mf_serialize(mtcars) test-serialization.R:3:2
 2.   └─reticulate:::MetaflowRObject(...) /Users/mdneuzerling/Dropbox/git/metaflow/R/R/serialization.R:41:2
 3.     └─reticulate:::py_call_impl(callable, dots$args, dots$keywords)
```

The `MetaflowRObject` class is defined during package build, and the corresponding Python class defined at the same time. When the packages is loaded that Python class no longer exists, and so I get the above error.

## 3rd attempt: recreate the Python class every time

If that's the case, I'll redefine the `MetaflowRObject` class each time an object is serialized. That is, I'll move the class definition into the body of the `mf_serialize` function. It's a little janky, but if it solves the problem I can look into cleaning it up afterwards. Unfortunately:

``` text
Metaflow 2.3.1 executing BasicArtifactsTestFlow for user:mdneuzerling
Validating your flow...
    The graph looks good!
2021-08-10 16:21:45.244 Workflow starting (run-id 1628576503868435):
2021-08-10 16:21:45.333 [1628576503868435/start/1 (pid 38284)] Task is starting.
2021-08-10 16:21:48.391 [1628576503868435/start/1 (pid 38284)] Can't pickle <class 'rpytools.call.MetaflowRObject'>: attribute lookup MetaflowRObject on rpytools.call failed
2021-08-10 16:21:48.486 [1628576503868435/start/1 (pid 38284)] Task failed.
2021-08-10 16:21:48.859 Workflow failed.
2021-08-10 16:21:48.859 Terminating 0 active tasks...
2021-08-10 16:21:48.859 Flushing logs...
    Step failure:
    Step start (task-id 1) failed.
```

The reticulate package provides a special `rpytools` module to Python. But when `pickle` goes looking for this it can't find it. Essentially, Pickle needs to be able to recreate objects of the class `rpytools.call.MetaflowRObject` but this class doesn't exist in any permanent sense outside of reticulate.

Supposedly this wouldn't be an issue if we were serialising with `dill`, but I didn't want to propose to the Metaflow developers that we completely overhaul the serialisation system. And if my solution was janky to begin with, then I should be happy to abandon it.

## 4th attempt: define the Python class without reticulate

I've done everything so far in R, but the Python parts of Metaflow aren't off-limits. The most sensible thing to do here is to define my `MetaflowRObject` class in Python, without reticulate. I put this in the `R.py` module in Metaflow Python:

``` python
class MetaflowRObject:
    def __init__(self, data, length):
        self.data = data
        self.length = length
    
    def __len__(self):
        return self.length
    
    def __eq__(self, other):
        return self.data == other.data
    
    def __getitem__(self, x):
        return MetaflowRObjectIndex(self, x)
```

When Python indexes a `MetaflowRObject` it needs to return another Python object, so I need to be careful about what happens when Python attempts to extract each value of a `foreach` argument. I define `MetaflowRObject.__getitem__` to return an object of class `MetaflowRObjectIndex`, which contains the full object as well as the index. This delays the actual indexing and deserialising until it can be done in R.

Note also the `r_index` property, which handles the difference between Python's 0-indexing and R's 1-indexing:

``` python
class MetaflowRObjectIndex:
    def __init__(self, full_object, index):
        self.full_object = full_object
        self.index = index
        
        if index < 0 or index >= len(full_object):
            raise IndexError("index of MetaflowRObject out of range")
        
    def __eq__(self, other):
        return (self.full_object == other.full_object and self.index == other.index)
        
    @property
    def r_index(self):
        return self.index + 1
```

Along with invertibility, my unit tests for serialization check for proper behaviour in Python land:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>test_that</span><span class='o'>(</span><span class='s'>"indexing is handled in R with special Python classes"</span>, <span class='o'>&#123;</span>
  
  <span class='nv'>a_list</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='s'>"red panda"</span>, <span class='m'>5</span>, <span class='kc'>FALSE</span><span class='o'>)</span>
  <span class='nv'>serialised_list</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/mf_serialize.html'>mf_serialize</a></span><span class='o'>(</span><span class='nv'>a_list</span><span class='o'>)</span>

  <span class='nf'>expect_s3_class</span><span class='o'>(</span><span class='nv'>serialised_list</span>, <span class='s'>"metaflow.R.MetaflowRObject"</span><span class='o'>)</span>
  <span class='nf'>expect_s3_class</span><span class='o'>(</span><span class='nv'>serialised_list</span><span class='o'>[</span><span class='m'>0L</span><span class='o'>]</span>, <span class='s'>"metaflow.R.MetaflowRObjectIndex"</span><span class='o'>)</span>

  <span class='nf'>expect_equal</span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/mf_serialize.html'>mf_deserialize</a></span><span class='o'>(</span><span class='nv'>serialised_list</span><span class='o'>[</span><span class='m'>0L</span><span class='o'>]</span><span class='o'>)</span>, <span class='s'>"red panda"</span><span class='o'>)</span>
  <span class='nf'>expect_equal</span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/mf_serialize.html'>mf_deserialize</a></span><span class='o'>(</span><span class='nv'>serialised_list</span><span class='o'>[</span><span class='m'>1L</span><span class='o'>]</span><span class='o'>)</span>, <span class='m'>5</span><span class='o'>)</span>
  <span class='nf'>expect_equal</span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/pkg/metaflow/man/mf_serialize.html'>mf_deserialize</a></span><span class='o'>(</span><span class='nv'>serialised_list</span><span class='o'>[</span><span class='m'>2L</span><span class='o'>]</span><span class='o'>)</span>, <span class='kc'>FALSE</span><span class='o'>)</span>

  <span class='nf'>expect_error</span><span class='o'>(</span>
    <span class='nv'>serialised_list</span><span class='o'>[</span><span class='o'>-</span><span class='m'>1L</span><span class='o'>]</span>,
    <span class='s'>"IndexError: index of MetaflowRObject out of range"</span>
  <span class='o'>)</span>
  <span class='nf'>expect_error</span><span class='o'>(</span>
    <span class='nv'>serialised_list</span><span class='o'>[</span><span class='m'>3L</span><span class='o'>]</span>,
    <span class='s'>"IndexError: index of MetaflowRObject out of range"</span>
  <span class='o'>)</span>
<span class='o'>&#125;</span><span class='o'>)</span></code></pre>

</div>

I really thought I had it here. And to be fair, this attempt made it further through the integration tests than any other. But eventually there was an error:

``` text
Metaflow 2.3.1 executing MergeArtifactsTestFlow for user:runner
Validating your flow...
    The graph looks good!
2021-08-14 11:03:42.638 Workflow starting (run-id 1628939022630948):
2021-08-14 11:03:42.645 [1628939022630948/start/1 (pid 12533)] Task is starting.
2021-08-14 11:03:45.725 [1628939022630948/start/1 (pid 12533)] Task finished successfully.
2021-08-14 11:03:45.732 [1628939022630948/foreach_split_x/2 (pid 12563)] Task is starting.
2021-08-14 11:03:48.776 [1628939022630948/foreach_split_x/2 (pid 12563)] Foreach yields 1 child steps.
2021-08-14 11:03:48.776 [1628939022630948/foreach_split_x/2 (pid 12563)] Task finished successfully.
2021-08-14 11:03:48.783 [1628939022630948/foreach_split_y/3 (pid 12593)] Task is starting.
2021-08-14 11:03:51.775 [1628939022630948/foreach_split_y/3 (pid 12593)] Foreach yields 1 child steps.
2021-08-14 11:03:51.775 [1628939022630948/foreach_split_y/3 (pid 12593)] Task finished successfully.
2021-08-14 11:03:51.782 [1628939022630948/foreach_split_z/4 (pid 12623)] Task is starting.
2021-08-14 11:03:54.709 [1628939022630948/foreach_split_z/4 (pid 12623)] Foreach yields 1 child steps.
2021-08-14 11:03:54.709 [1628939022630948/foreach_split_z/4 (pid 12623)] Task finished successfully.
2021-08-14 11:03:54.717 [1628939022630948/foreach_inner/5 (pid 12654)] Task is starting.
2021-08-14 11:03:57.692 [1628939022630948/foreach_inner/5 (pid 12654)] Task finished successfully.
2021-08-14 11:03:57.700 [1628939022630948/foreach_join_z/6 (pid 12708)] Task is starting.
2021-08-14 11:04:00.630 [1628939022630948/foreach_join_z/6 (pid 12708)] <flow MergeArtifactsTestFlow step foreach_join_z[0,0]> failed:
2021-08-14 11:04:00.643 [1628939022630948/foreach_join_z/6 (pid 12708)] Evaluation error: has_correct_error_message is not TRUE.
2021-08-14 11:04:00.658 [1628939022630948/foreach_join_z/6 (pid 12708)] Task failed.
2021-08-14 11:04:00.659 Workflow failed.
2021-08-14 11:04:00.659 Terminating 0 active tasks...
2021-08-14 11:04:00.659 Flushing logs...
    Step failure:
    Step foreach_join_z (task-id 6) failed.
```

There's some sort of mishap with how these various artefacts are merged after being split.

## Where to from here

This is a tough thing to debug. I'm running code across two different languages and multiple processes.

I can think of one way forward. I should try to create a simpler reproducible example. The `MetaflowRObject` class doesn't *need* to come from R, so I could potentially create a reproducible example in Python only. I might not be able to immediately solve the problem, but I can try to simplify it.

I also need to closely study the way that Metaflow splits steps and merges artifacts. There could be something here that I'm missing. Maybe if I re-read the source code something will jump out at me!

But if nothing else, this has been a fun exploration of the way that R and Python interact. I've learnt a lot about reticulate, data types, and pickles.

## Bonus: simplifying `mf_deserialize` with S3 classes

I've focussed on `mf_serialize` here but every implementation of `mf_serialize` has a corresponding `mf_deserialize`. There's also a need for backwards compatibility, to be able to deserialize objects from older Metaflow runs.

Under the definition of `mf_serialize` in my 4th attempt, I have different deserialisation approaches for `MetaflowRObject`, `MetaflowRObjectIndex`, `raw`, and default method which leaves all other types untouched. Rather than polluting the `mf_deserialize` function with a convoluted chain of `if-else` branches, I can keep things tidy by leaning once again on S3.

Python classes can be given the S3 treatment in R. Their classes are already available to dispatch on. So I can define a method for an object of class `metaflow.R.MetaflowRObject`.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>mf_deserialize</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'><a href='https://rdrr.io/r/base/UseMethod.html'>UseMethod</a></span><span class='o'>(</span><span class='s'>"mf_deserialize"</span>, <span class='nv'>object</span><span class='o'>)</span>
<span class='o'>&#125;</span>

<span class='nv'>mf_deserialize.metaflow.R.MetaflowRObject</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>unserialize</a></span><span class='o'>(</span><span class='nv'>object</span><span class='o'>$</span><span class='nv'>data</span><span class='o'>)</span>
<span class='o'>&#125;</span>

<span class='nv'>mf_deserialize.metaflow.R.MetaflowRObjectIndex</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nf'>mf_deserialize.metaflow.R.MetaflowRObject</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>$</span><span class='nv'>full_object</span><span class='o'>)</span><span class='o'>[[</span><span class='nv'>object</span><span class='o'>$</span><span class='nv'>r_index</span><span class='o'>]</span><span class='o'>]</span>
<span class='o'>&#125;</span>

<span class='nv'>mf_deserialize.raw</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'><a href='https://rdrr.io/r/base/conditions.html'>tryCatch</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/serialize.html'>unserialize</a></span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span>, error <span class='o'>=</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>e</span><span class='o'>)</span> <span class='o'>&#123;</span><span class='nv'>object</span><span class='o'>&#125;</span><span class='o'>)</span>
<span class='o'>&#125;</span>

<span class='nv'>mf_deserialize.default</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>object</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>object</span>
<span class='o'>&#125;</span></code></pre>

</div>

The downside is that I need to export the `mf_deserialize` function (and, to be consistent, `mf_serialize`). It makes the namespace a little dirtier; users shouldn't need to use these functions directly, so I'd prefer it if they were hidden.

------------------------------------------------------------------------

[The image at the top of this page is by Johannes Plenio from Pexels](https://www.pexels.com/photo/brown-and-black-brick-wall-2259233/)

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
<span class='c'>#&gt;  date     2021-09-19                  </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ─ Packages ───────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  package     * version    date       lib source                         </span>
<span class='c'>#&gt;  assertthat    0.2.1      2019-03-21 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cachem        1.0.4      2021-02-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  callr         3.7.0      2021-04-20 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cli           3.0.1      2021-07-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  crayon        1.4.1      2021-02-08 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  data.table    1.14.0     2021-02-21 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  DBI           1.1.1      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  desc          1.3.0      2021-03-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  devtools      2.4.0      2021-04-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  digest        0.6.27     2020-10-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  downlit       0.2.1      2020-11-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  dplyr       * 1.0.5      2021-03-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ellipsis      0.3.2      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  evaluate      0.14       2019-05-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fansi         0.5.0      2021-05-25 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fastmap       1.1.0      2021-01-25 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fs            1.5.0      2020-07-31 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  generics      0.1.0      2020-10-31 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  glue          1.4.2      2020-08-27 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  highr         0.9        2021-04-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  htmltools     0.5.2      2021-08-25 [1] CRAN (R 4.1.1)                 </span>
<span class='c'>#&gt;  hugodown      0.0.0.9000 2021-09-18 [1] Github (r-lib/hugodown@168a361)</span>
<span class='c'>#&gt;  jsonlite      1.7.2      2020-12-09 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  knitr         1.34       2021-09-09 [1] CRAN (R 4.1.1)                 </span>
<span class='c'>#&gt;  lattice       0.20-44    2021-05-02 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lifecycle     1.0.0      2021-02-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  magrittr      2.0.1      2020-11-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  Matrix        1.3-3      2021-05-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  memoise       2.0.0      2021-01-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  metaflow    * 2.3.1      2021-08-16 [1] local                          </span>
<span class='c'>#&gt;  pillar        1.6.1      2021-05-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgbuild      1.2.0      2020-12-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgconfig     2.0.3      2019-09-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgload       1.2.1      2021-04-06 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  png           0.1-7      2013-12-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  prettyunits   1.1.1      2020-01-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  processx      3.5.2      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ps            1.6.0      2021-02-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  purrr         0.3.4      2020-04-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  R6            2.5.1      2021-08-19 [1] CRAN (R 4.1.1)                 </span>
<span class='c'>#&gt;  Rcpp          1.0.7      2021-07-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  remotes       2.3.0      2021-04-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  reticulate    1.20       2021-05-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rlang         0.4.11     2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rmarkdown     2.11       2021-09-14 [1] CRAN (R 4.1.1)                 </span>
<span class='c'>#&gt;  rprojroot     2.0.2      2020-11-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  sessioninfo   1.1.1      2018-11-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  stringi       1.7.4      2021-08-25 [1] CRAN (R 4.1.1)                 </span>
<span class='c'>#&gt;  stringr       1.4.0      2019-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  testthat      3.0.4      2021-07-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tibble        3.1.2      2021-05-16 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tidyselect    1.1.1      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  usethis       2.0.1      2021-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  utf8          1.2.1      2021-03-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  vctrs         0.3.8      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  withr         2.4.2      2021-04-18 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  xfun          0.26       2021-09-14 [1] CRAN (R 4.1.1)                 </span>
<span class='c'>#&gt;  yaml          2.2.1      2020-02-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; [1] /Library/Frameworks/R.framework/Versions/4.1-arm64/Resources/library</span></code></pre>

</div>

