---
title: My First CRAN Package
author: ~
date: '2021-05-23'
slug: my-first-cran-package
tags:
    - r
images: ["/img/badges.png"]
output: hugodown::md_document
rmd_hash: 2fe7f53ee9bf51ce

---

For my first R package to submit to CRAN I chose something simple --- an API wrapper around [my state's public transport API](https://www.ptv.vic.gov.au/footer/data-and-reporting/datasets/ptv-timetable-api/). It's not the most exciting contribution to open source code, but you can learn a lot by writing an API wrapper.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/routes.html'>routes</a></span><span class='o'>(</span><span class='o'>)</span> |&gt; <span class='nf'><a href='https://dplyr.tidyverse.org/reference/group_by.html'>group_by</a></span><span class='o'>(</span><span class='nv'>route_type</span><span class='o'>)</span> |&gt; <span class='nf'><a href='https://dplyr.tidyverse.org/reference/sample_n.html'>sample_n</a></span><span class='o'>(</span><span class='m'>2</span><span class='o'>)</span>
<span class='c'>#&gt; <span style='color: #555555;'># A tibble: 10 x 9</span></span>
<span class='c'>#&gt; <span style='color: #555555;'># Groups:   route_type [5]</span></span>
<span class='c'>#&gt;    route_id route_gtfs_id route_name route_type route_type_desc… route_number geopath service_status</span>
<span class='c'>#&gt;       <span style='color: #555555;font-style: italic;'>&lt;int&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>         </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>           </span><span style='color: #555555;font-style: italic;'>&lt;int&gt;</span><span> </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>            </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>        </span><span style='color: #555555;font-style: italic;'>&lt;list&gt;</span><span>  </span><span style='color: #555555;font-style: italic;'>&lt;chr&gt;</span><span>         </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 1</span><span>       12 2-SDM         Sandringh…          0 Train            </span><span style='color: #BB0000;'>NA</span><span>           </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 2</span><span>       16 2-WBE         Werribee            0 Train            </span><span style='color: #BB0000;'>NA</span><span>           </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 3</span><span>     </span><span style='text-decoration: underline;'>1</span><span>002 3-082         Moonee Po…          1 Tram             82           </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 4</span><span>     </span><span style='text-decoration: underline;'>1</span><span>881 3-086         Bundoora …          1 Tram             86           </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 5</span><span>    </span><span style='text-decoration: underline;'>13</span><span>631 6-LGs         Lancefiel…          2 Bus              </span><span style='color: #BB0000;'>NA</span><span>           </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 6</span><span>     </span><span style='text-decoration: underline;'>5</span><span>334 4-850         Dandenong…          2 Bus              850          </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 7</span><span>     </span><span style='text-decoration: underline;'>1</span><span>767 1-V30         Mount Gam…          3 Vline            </span><span style='color: #BB0000;'>NA</span><span>           </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 8</span><span>     </span><span style='text-decoration: underline;'>1</span><span>838 1-V37         Nhill - M…          3 Vline            </span><span style='color: #BB0000;'>NA</span><span>           </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'> 9</span><span>    </span><span style='text-decoration: underline;'>13</span><span>059 8-943         Night Bus…          4 Night Bus        943          </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'>10</span><span>     </span><span style='text-decoration: underline;'>8</span><span>956 8-95i         Night Bus…          4 Night Bus        951          </span><span style='color: #555555;'>&lt;tibbl</span><span>… Good Service  </span></span>
<span class='c'>#&gt; <span style='color: #555555;'># … with 1 more variable: service_status_timestamp &lt;dttm&gt;</span></span></code></pre>

</div>

### Ease of use is everything

API wrappers don't introduce new functionality; there's nothing stopping

### Caching is a good idea

### Authentication is hard

### CRAN is fun

### URL parameters are tricky

-   System for [`?`](https://rdrr.io/r/utils/Question.html) and [`&`](https://rdrr.io/r/base/Logic.html)
-   `TRUE` becomes `true` (maybe, can't assume this for all APIs)
-   I implemented a system such that `NULL`s aren't included

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>add_parameter</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span>
  <span class='nv'>request</span>,
  <span class='nv'>parameter_name</span>,
  <span class='nv'>parameter_value</span>,
  <span class='nv'>.combine</span> <span class='o'>=</span> <span class='s'>"repeat_name"</span>
<span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='o'>(</span><span class='nv'>parameter_value</span><span class='o'>)</span> <span class='o'>||</span> <span class='nf'><a href='https://rdrr.io/r/base/length.html'>length</a></span><span class='o'>(</span><span class='nv'>parameter_value</span><span class='o'>)</span> <span class='o'>==</span> <span class='m'>0</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/function.html'>return</a></span><span class='o'>(</span><span class='nv'>request</span><span class='o'>)</span>
  <span class='o'>&#125;</span>

  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/length.html'>length</a></span><span class='o'>(</span><span class='nv'>parameter_value</span><span class='o'>)</span> <span class='o'>==</span> <span class='m'>1</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nv'>conjunction</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/grep.html'>grepl</a></span><span class='o'>(</span><span class='s'>"\\?"</span>, <span class='nv'>request</span><span class='o'>)</span>, <span class='s'>"&amp;"</span>, <span class='s'>"?"</span><span class='o'>)</span>
    <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/logical.html'>is.logical</a></span><span class='o'>(</span><span class='nv'>parameter_value</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='nv'>parameter_value</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/ifelse.html'>ifelse</a></span><span class='o'>(</span><span class='nv'>parameter_value</span>, <span class='s'>"true"</span>, <span class='s'>"false"</span><span class='o'>)</span>
    <span class='o'>&#125;</span>
    <span class='nf'>glue</span><span class='nf'>::</span><span class='nf'><a href='https://glue.tidyverse.org/reference/glue.html'>glue</a></span><span class='o'>(</span><span class='s'>"&#123;request&#125;&#123;conjunction&#125;&#123;parameter_name&#125;=&#123;parameter_value&#125;"</span><span class='o'>)</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='kr'>if</span> <span class='o'>(</span><span class='nv'>.combine</span> <span class='o'>==</span> <span class='s'>"repeat_name"</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'>for</span> <span class='o'>(</span><span class='nv'>value</span> <span class='kr'>in</span> <span class='nv'>parameter_value</span><span class='o'>)</span> <span class='o'>&#123;</span>
      <span class='nv'>request</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameter.html'>add_parameter</a></span><span class='o'>(</span>
        <span class='nv'>request</span>,
        <span class='nv'>parameter_name</span>,
        <span class='nv'>value</span>,
        .combine <span class='o'>=</span> <span class='nv'>.combine</span>
      <span class='o'>)</span>
    <span class='o'>&#125;</span>
    <span class='nv'>request</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='kr'>if</span> <span class='o'>(</span><span class='nv'>.combine</span> <span class='o'>==</span> <span class='s'>"with_commas"</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameter.html'>add_parameter</a></span><span class='o'>(</span><span class='nv'>request</span>, <span class='nv'>parameter_name</span>, <span class='nv'>parameter_value</span>, .combine <span class='o'>=</span> <span class='s'>","</span><span class='o'>)</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='kr'>if</span> <span class='o'>(</span><span class='nv'>.combine</span> <span class='o'>==</span> <span class='s'>"with_hex_commas"</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameter.html'>add_parameter</a></span><span class='o'>(</span><span class='nv'>request</span>, <span class='nv'>parameter_name</span>, <span class='nv'>parameter_value</span>, .combine <span class='o'>=</span> <span class='s'>"%2C"</span><span class='o'>)</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='o'>&#123;</span>
    <span class='nv'>combined_value</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste</a></span><span class='o'>(</span><span class='nv'>parameter_value</span>, collapse <span class='o'>=</span> <span class='nv'>.combine</span><span class='o'>)</span>
    <span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameter.html'>add_parameter</a></span><span class='o'>(</span><span class='nv'>request</span>, <span class='nv'>parameter_name</span>, <span class='nv'>combined_value</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
<span class='o'>&#125;</span></code></pre>

</div>

To make life easier, I can append multiple parameters at once with `add_parameters`. This lets me specify each parameter as a function argument, so [`add_parameters(request, x = "y")`](https://rdrr.io/pkg/ptvapi/man/add_parameters.html) is equivalent to [`add_parameter(request, "x", "y")`](https://rdrr.io/pkg/ptvapi/man/add_parameter.html).

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>add_parameters</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>request</span>, <span class='nv'>...</span>, <span class='nv'>.combine</span> <span class='o'>=</span> <span class='s'>"repeat_name"</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='nv'>dots</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/list.html'>list</a></span><span class='o'>(</span><span class='nv'>...</span><span class='o'>)</span>
  <span class='nv'>dots_names</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/names.html'>names</a></span><span class='o'>(</span><span class='nv'>dots</span><span class='o'>)</span>
  <span class='kr'>for</span> <span class='o'>(</span><span class='nv'>i</span> <span class='kr'>in</span> <span class='nf'><a href='https://rdrr.io/r/base/seq.html'>seq_along</a></span><span class='o'>(</span><span class='nv'>dots</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nv'>dot_name</span> <span class='o'>&lt;-</span> <span class='nv'>dots_names</span><span class='o'>[</span><span class='nv'>i</span><span class='o'>]</span>
    <span class='nv'>dot_value</span> <span class='o'>&lt;-</span> <span class='nv'>dots</span><span class='o'>[[</span><span class='nv'>i</span><span class='o'>]</span><span class='o'>]</span>
    <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='o'>(</span><span class='nv'>dot_name</span><span class='o'>)</span> <span class='o'>||</span> <span class='nv'>dot_name</span> <span class='o'>==</span> <span class='s'>""</span><span class='o'>)</span> <span class='kr'><a href='https://rdrr.io/r/base/stop.html'>stop</a></span><span class='o'>(</span><span class='s'>"Parameters must be named"</span><span class='o'>)</span>
    <span class='c'># add_parameter will error if dot_value if not a singletons, and will</span>
    <span class='c'># return the request unaltered if dot_value is NULL</span>
    <span class='nv'>request</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameter.html'>add_parameter</a></span><span class='o'>(</span><span class='nv'>request</span>, <span class='nv'>dot_name</span>, <span class='nv'>dot_value</span>, .combine <span class='o'>=</span> <span class='nv'>.combine</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
  <span class='nv'>request</span>
<span class='o'>&#125;</span></code></pre>

</div>

Some examples to see this all put together:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameters.html'>add_parameters</a></span><span class='o'>(</span>
  <span class='s'>"www.example.com"</span>,
  animal <span class='o'>=</span> <span class='s'>"crocodile"</span>
<span class='o'>)</span>
<span class='c'>#&gt; www.example.com?animal=crocodile</span>
<span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameters.html'>add_parameters</a></span><span class='o'>(</span>
  <span class='s'>"www.example.com"</span>,
  animal <span class='o'>=</span> <span class='s'>"crocodile"</span>,
  food <span class='o'>=</span> <span class='s'>"cherries"</span>,
  red_pandas_are_cute <span class='o'>=</span> <span class='kc'>TRUE</span>,
  colour <span class='o'>=</span> <span class='kc'>NULL</span>
<span class='o'>)</span>
<span class='c'>#&gt; www.example.com?animal=crocodile&amp;food=cherries&amp;red_pandas_are_cute=true</span>
<span class='nf'><a href='https://rdrr.io/pkg/ptvapi/man/add_parameters.html'>add_parameters</a></span><span class='o'>(</span>
  <span class='s'>"www.example.com"</span>,
  animal <span class='o'>=</span> <span class='s'>"crocodile"</span>,
  numbers <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span><span class='m'>1</span>, <span class='m'>2</span>, <span class='m'>3</span><span class='o'>)</span>,
  .combine <span class='o'>=</span> <span class='s'>"repeat_name"</span>
<span class='o'>)</span>
<span class='c'>#&gt; www.example.com?animal=crocodile&amp;numbers=1&amp;numbers=2&amp;numbers=3</span></code></pre>

</div>

### CI/CD is essential

### Types are important

### Badges are cute

------------------------------------------------------------------------

Thank you to Phizz Leeder for creating the `ptvapi` hex logo.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/sessioninfo/man/session_info.html'>session_info</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; ─ Session info ───────────────────────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  setting  value                                    </span>
<span class='c'>#&gt;  version  R version 4.1.0 alpha (2021-04-26 r80229)</span>
<span class='c'>#&gt;  os       macOS Big Sur 11.2.3                     </span>
<span class='c'>#&gt;  system   aarch64, darwin20                        </span>
<span class='c'>#&gt;  ui       X11                                      </span>
<span class='c'>#&gt;  language (EN)                                     </span>
<span class='c'>#&gt;  collate  en_AU.UTF-8                              </span>
<span class='c'>#&gt;  ctype    en_AU.UTF-8                              </span>
<span class='c'>#&gt;  tz       Australia/Melbourne                      </span>
<span class='c'>#&gt;  date     2021-05-16                               </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ─ Packages ───────────────────────────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  package     * version    date       lib source                         </span>
<span class='c'>#&gt;  assertthat    0.2.1      2019-03-21 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cachem        1.0.4      2021-02-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  callr         3.7.0      2021-04-20 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cli           2.5.0      2021-04-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  crayon        1.4.1      2021-02-08 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  curl          4.3.1      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  DBI           1.1.1      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  desc          1.3.0      2021-03-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  devtools      2.4.0      2021-04-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  digest        0.6.27     2020-10-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  downlit       0.2.1      2020-11-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  dplyr       * 1.0.5      2021-03-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ellipsis      0.3.2      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  evaluate      0.14       2019-05-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fansi         0.4.2      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fastmap       1.1.0      2021-01-25 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fs            1.5.0      2020-07-31 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  generics      0.1.0      2020-10-31 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  glue          1.4.2      2020-08-27 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  htmltools     0.5.1.1    2021-01-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  httr          1.4.2      2020-07-20 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  hugodown      0.0.0.9000 2021-05-16 [1] Github (r-lib/hugodown@97ea0cd)</span>
<span class='c'>#&gt;  jsonlite      1.7.2      2020-12-09 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  knitr         1.33       2021-04-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lifecycle     1.0.0      2021-02-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  magrittr      2.0.1      2020-11-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  memoise       2.0.0      2021-01-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pillar        1.6.0      2021-04-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgbuild      1.2.0      2020-12-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgconfig     2.0.3      2019-09-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgload       1.2.1      2021-04-06 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  prettyunits   1.1.1      2020-01-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  processx      3.5.2      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ps            1.6.0      2021-02-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ptvapi      * 2.0.0      2021-05-02 [1] local                          </span>
<span class='c'>#&gt;  purrr         0.3.4      2020-04-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  R6            2.5.0      2020-10-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  remotes       2.3.0      2021-04-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rlang         0.4.11     2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rmarkdown     2.8        2021-05-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rprojroot     2.0.2      2020-11-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rstudioapi    0.13       2020-11-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  sessioninfo   1.1.1      2018-11-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  stringi       1.6.1      2021-05-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  stringr       1.4.0      2019-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  testthat      3.0.2      2021-02-14 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tibble        3.1.1      2021-04-18 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  tidyselect    1.1.1      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  usethis       2.0.1      2021-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  utf8          1.2.1      2021-03-12 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  vctrs         0.3.8      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  withr         2.4.2      2021-04-18 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  xfun          0.22       2021-03-11 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  yaml          2.2.1      2020-02-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; [1] /Library/Frameworks/R.framework/Versions/4.1-arm64/Resources/library</span></code></pre>

</div>

