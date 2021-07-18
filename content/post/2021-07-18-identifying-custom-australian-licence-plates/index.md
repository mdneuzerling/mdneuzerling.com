---
title: "Identifying Custom Australian Licence Plates"
author: ~
date: '2021-07-18'
slug: identifying-custom-australian-licence-plates
tags:
    - python
images: ["/img/cars.jpg"]
output: hugodown::md_document
rmd_hash: aa7ccf48bdb2940d

---

In case this saves anyone some time, here's a quick bit of regex and Python code for identifying if a given licence plate is standard or custom (personalised) in a given state.

I can't promise that this logic is correct or up to date. Some of the rules used are a bit more general than they need to be. I also tended to ignore rules before 1970. The rules come from:

-   <https://en.wikipedia.org/wiki/Vehicle_registration_plates_of_Australia>
-   <https://www.vicroads.vic.gov.au/registration/number-plates/general-issue-number-plates>

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>import re

# Takes a pattern like xxxddd (for three letters followed by three numbers)
# and converts it to regex. Other characters are left as is in the regex
# pattern string. This is helpful for states like SA in which every modern
# licence plate begins with an "S".
def match_plate_pattern(plate, pattern):
    pattern = pattern.replace('x','[A-Za-z]').replace('d','[0-9]')
    return(re.fullmatch(pattern, plate))

licence_plate_patterns = {
    "VIC": ["dxxdxx", # current car 
            "xxxddd", # old car
            "dxdxx", # current motorcycle
            "xxddd"], # old motorcycle
    "NSW": ["xxddxx", # current car
            "xxxddx", # old car
            "xxxdd"], # motorcycles
    "QLD": ["dddxxx", # current car
            "dddxxd", # future car
            "dddxx"], # motorcycles
    "SA": ["Sdddxxx", # current car
           "dddxxx", # old car
           "Sddxxx", # current motorcycles
           "ddxxx"], # old motorcycles
    "WA": ["1xxxddd", # current style plates
            "xxxddd", # old style plates before 1978
            "dxxddd", # old style plates 1978--1997
            "1ddxxx"], # current motorcycles (1997 onwards)]
    "TAS": ["xddxx", # current style plates
            "xxdddd", # old style plates 1970--2008
            "xxxddd", # old style plates 1954--1970
            "xxddd", # motorcycles
            "xdddx"], # motorcycles
    "ACT": ["xxxddx", # current style plates
            "xxxddd", # future style plates
            "xdddd"], # motorcycles
    "NT": ["xxddxx", # current style plates
           "dddddd", # future style plates
           "xdddd", # current motorcycles
           "ddddd"] # old motorcycles 1979--2011
}
    
def plate_type(plate, state):

    # remove anything that isn't a letter or number
    plate = re.sub(r'[\W_]+', '', str(plate))

    plate_matches = [match_plate_pattern(plate, pattern) for pattern 
                     in licence_plate_patterns[state]]

    if plate == "": 
        return("no_plate")
    elif any(plate_matches):
        return("standard_plate")
    else:
        return("custom_plate")</code></pre>

</div>

And some Victorian examples:

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'>plate_type("ABC-123", "VIC")
#> 'standard_plate'
plate_type("XY123", "VIC")
#> 'standard_plate'
plate_type("1AB-2CD", "VIC")
#> 'standard_plate'
plate_type("HOTROD", "VIC")
#> 'custom_plate'</code></pre>

</div>

------------------------------------------------------------------------

[The image at the top of this page is in the public domain.](https://unsplash.com/photos/Jk3-Uhdwjcs)

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
<span class='c'>#&gt;  date     2021-07-18                  </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ─ Packages ───────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  package     * version    date       lib source                         </span>
<span class='c'>#&gt;  cachem        1.0.4      2021-02-13 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  callr         3.7.0      2021-04-20 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  cli           2.5.0      2021-04-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  crayon        1.4.1      2021-02-08 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  desc          1.3.0      2021-03-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  devtools      2.4.0      2021-04-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  digest        0.6.27     2020-10-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  downlit       0.2.1      2020-11-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ellipsis      0.3.2      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  evaluate      0.14       2019-05-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fansi         0.4.2      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fastmap       1.1.0      2021-01-25 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  fs            1.5.0      2020-07-31 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  glue          1.4.2      2020-08-27 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  htmltools     0.5.1.1    2021-01-22 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  hugodown      0.0.0.9000 2021-05-16 [1] Github (r-lib/hugodown@97ea0cd)</span>
<span class='c'>#&gt;  jsonlite      1.7.2      2020-12-09 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  knitr         1.33       2021-04-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lattice       0.20-44    2021-05-02 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  lifecycle     1.0.0      2021-02-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  magrittr      2.0.1      2020-11-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  Matrix        1.3-3      2021-05-04 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  memoise       2.0.0      2021-01-26 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgbuild      1.2.0      2020-12-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  pkgload       1.2.1      2021-04-06 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  png           0.1-7      2013-12-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  prettyunits   1.1.1      2020-01-24 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  processx      3.5.2      2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  ps            1.6.0      2021-02-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  purrr         0.3.4      2020-04-17 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  R6            2.5.0      2020-10-28 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  Rcpp          1.0.6      2021-01-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  remotes       2.3.0      2021-04-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  reticulate    1.20       2021-05-03 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rlang         0.4.11     2021-04-30 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rmarkdown     2.8        2021-05-07 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  rprojroot     2.0.2      2020-11-15 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  sessioninfo   1.1.1      2018-11-05 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  stringi       1.6.1      2021-05-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  stringr       1.4.0      2019-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  testthat      3.0.4      2021-07-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  usethis       2.0.1      2021-02-10 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  vctrs         0.3.8      2021-04-29 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  withr         2.4.2      2021-04-18 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  xfun          0.22       2021-03-11 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt;  yaml          2.2.1      2020-02-01 [1] CRAN (R 4.1.0)                 </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; [1] /Library/Frameworks/R.framework/Versions/4.1-arm64/Resources/library</span></code></pre>

</div>

