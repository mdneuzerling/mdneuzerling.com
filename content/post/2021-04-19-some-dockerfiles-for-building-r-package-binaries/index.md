---
title: Some Dockerfiles for Building R Package Binaries
author: ~
date: '2021-04-19'
slug: some-dockerfiles-for-building-r-package-binaries
category: code
tags:
    - R
featured: "/img/featured/lego-build.webp"
output: hugodown::md_document
rmd_hash: be71fd9c83705fb7

---

I went down a strange path recently, trying to compile binaries of R packages for Linux. I'm not sure why --- this area is pretty much covered by the [RStudio Package Manager](https://packagemanager.rstudio.com/client/#/). I'll leave my Dockerfiles here in case they're of any use to a future wayward R programmer.

The intention here is to build a Docker image that can build an R binary with the below command. I'm trying to build x86 binaries on my ARM Macbook, so I'm specifying the platform during both `build` and `run`.

```bash
docker run --platform linux/amd64 -v ~/packages:/packages $IMAGE $PACKAGE $VERSION
```

This will output the compiled binary into a subdirectory `~/packages` corresponding to the target version of R. These binaries are not portable --- they depend very much on the Linux distribution used to build them.

## Method 1: `conda-build`

`conda` is a package manager mostly associated with Python, but it can also be used for R and other languages.

The Dockerfile below installs Miniconda and `conda-build`, which it uses to build the R package binaries. These are binaries that must be installed with `conda`, rather than through R directly.

I use `mamba` and `boa`, which provide faster alternatives to `conda install` and `conda build`, respectively.

Every time `conda`/`mamba` builds an R package, it fetches all dependencies from scratch. To speed this up, I install R in the `docker build` process so that it's cached. Finally I hardcode the script that's used to build the R package, depending on whether a version is specified.

```bash
ARG OS_IDENTIFIER=ubuntu
ARG OS_TAG=20.04
ARG PLATFORM=linux/amd64

FROM --platform=${PLATFORM} ${OS_IDENTIFIER}:${OS_TAG} 

ENV LANG en_US.UTF-8

RUN apt-get update && apt-get install -y curl

# Install Miniconda and conda-build, which is needed to compile R packages
# for conda-forge 
ARG MINICONDA_VERSION=py38_4.9.2
ARG MINICONDA_INSTALLER=Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh
RUN curl -LO https://repo.anaconda.com/miniconda/${MINICONDA_INSTALLER} \
    && bash ${MINICONDA_INSTALLER} -p /miniconda -b \
    && rm ${MINICONDA_INSTALLER}
ENV PATH=/miniconda/bin:${PATH}
RUN conda install conda-build

# Mamba is much faster for installing packages, and boa lets us use it
# when building packages
RUN conda install -c conda-forge mamba boa

# conda-build (and its mamba equivalent) will always reach out to a repository
# to install dependencies, rather than using pre-installed packages. However,
# by installing r-base now we can cache the required packages, so that R
# doesn't have to be downloaded each time a package is built.
ENV R_VERSION=4.0.3
RUN mamba install -c conda-forge r-base=${R_VERSION}

# Compiled packages are outputted to this directory. When this container is run,
# /packages can be used as a target for -v 
RUN mkdir -p /packages/R-{$R_VERSION}

RUN echo "#!/bin/bash" > build_r_package.sh \
  && echo ' \n\
package=$1 \n\
version=$2 \n\
if [[ -n "$2" ]]; then \n\
    echo "Building r-$package-$version" \n\
    conda skeleton cran --version $version $package \n\
    conda mambabuild --R ${R_VERSION} -c conda-forge --output-folder /packages/R-${R_VERSION} r-$package-$version \n\
else \n\
    echo "Building r-$package" \n\
    conda skeleton cran $package \n\
    conda mambabuild --R ${R_VERSION} -c conda-forge --output-folder /packages/R-${R_VERSION} r-$package \n\
fi ' >> build_r_package.sh \
  && chmod +x build_r_package.sh

ENTRYPOINT ["/build_r_package.sh"]
```

Even with `mamba` this is a slow process --- it takes over 10 minutes to compile the `glue` package, which has minimal dependencies.

## Method 2: Just R

Using just R requires a bit more logic. I've separated out some R helper scripts, as well as the bash script that does the actual building. I start with `rocker` which already has R installed. I also need the `remotes` package to install package dependencies.

```dockerfile
FROM rocker/r-ver:4.0.3

RUN apt-get update && apt-get install -y curl

RUN Rscript -e 'install.packages("remotes")'

ENV R_VERSION=4.0.3
RUN mkdir -p /packages/R-${R_VERSION}
RUN mkdir /scripts

ADD helpers.R /scripts/helpers.R
ADD build-R-package.sh /scripts/build-R-package.sh
RUN chmod +x /scripts/build-R-package.sh

ENTRYPOINT ["/scripts/build-R-package.sh"]
```

The R helper functions I need query CRAN to determine the latest available version of a package. If the desired version is not the latest, then the source needs to be downloaded from the CRAN archives.

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nv'>cran_version</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>package</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/options.html'>getOption</a></span><span class='o'>(</span><span class='s'>"repos"</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>||</span> <span class='nf'><a href='https://rdrr.io/r/base/options.html'>getOption</a></span><span class='o'>(</span><span class='s'>"repos"</span><span class='o'>)</span> <span class='o'>==</span> <span class='s'>"@CRAN@"</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nf'><a href='https://rdrr.io/r/base/options.html'>options</a></span><span class='o'>(</span>repos <span class='o'>=</span> <span class='nf'><a href='https://rdrr.io/r/base/c.html'>c</a></span><span class='o'>(</span>CRAN <span class='o'>=</span> <span class='s'>"https://cloud.r-project.org/"</span><span class='o'>)</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
  <span class='nv'>available</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/as.data.frame.html'>as.data.frame</a></span><span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/utils/available.packages.html'>available.packages</a></span><span class='o'>(</span><span class='o'>)</span><span class='o'>)</span>
  <span class='nv'>filtered</span> <span class='o'>&lt;-</span> <span class='nv'>available</span><span class='o'>[</span><span class='nv'>available</span><span class='o'>$</span><span class='nv'>Package</span> <span class='o'>==</span> <span class='nv'>package</span>,<span class='o'>]</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/nrow.html'>nrow</a></span><span class='o'>(</span><span class='nv'>filtered</span><span class='o'>)</span> <span class='o'>!=</span> <span class='m'>1</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='kr'><a href='https://rdrr.io/r/base/stop.html'>stop</a></span><span class='o'>(</span><span class='nv'>package</span>, <span class='s'>" is not available on CRAN"</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
  <span class='nv'>filtered</span><span class='o'>$</span><span class='nv'>Version</span>
<span class='o'>&#125;</span>

<span class='nv'>cran_source_url</span> <span class='o'>&lt;-</span> <span class='kr'>function</span><span class='o'>(</span><span class='nv'>package</span>, <span class='nv'>version</span> <span class='o'>=</span> <span class='kc'>NULL</span><span class='o'>)</span> <span class='o'>&#123;</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nf'><a href='https://rdrr.io/r/base/NULL.html'>is.null</a></span><span class='o'>(</span><span class='nv'>version</span><span class='o'>)</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nv'>version</span> <span class='o'>&lt;-</span> <span class='nf'>cran_version</span><span class='o'>(</span><span class='nv'>package</span><span class='o'>)</span>
    <span class='nv'>latest_version</span> <span class='o'>&lt;-</span> <span class='kc'>TRUE</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='o'>&#123;</span>
    <span class='nv'>latest_version</span> <span class='o'>&lt;-</span> <span class='o'>(</span><span class='nv'>version</span> <span class='o'>==</span> <span class='nf'>cran_version</span><span class='o'>(</span><span class='nv'>package</span><span class='o'>)</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
  <span class='nv'>bundle</span> <span class='o'>&lt;-</span> <span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='o'>(</span><span class='nv'>package</span>, <span class='s'>"_"</span>, <span class='nv'>version</span>, <span class='s'>".tar.gz"</span><span class='o'>)</span>
  <span class='kr'>if</span> <span class='o'>(</span><span class='nv'>latest_version</span><span class='o'>)</span> <span class='o'>&#123;</span>
    <span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='o'>(</span><span class='s'>"https://cran.r-project.org/src/contrib/"</span>, <span class='nv'>bundle</span><span class='o'>)</span>
  <span class='o'>&#125;</span> <span class='kr'>else</span> <span class='o'>&#123;</span>
    <span class='nf'><a href='https://rdrr.io/r/base/paste.html'>paste0</a></span><span class='o'>(</span><span class='s'>"https://cran.r-project.org/src/contrib/Archive/"</span>, <span class='nv'>package</span>, <span class='s'>"/"</span>, <span class='nv'>bundle</span><span class='o'>)</span>
  <span class='o'>&#125;</span>
<span class='o'>&#125;</span></code></pre>

</div>

The bash script calls on the helpers as needed. If no version is specified, the latest version is used. Then the source is downloaded from CRAN and the package is built. It's also installed --- building and installing are closely related with R. Finally the resulting binary is moved to the `packages` directory.

```bash
#!/bin/bash

package=$1
version=$2
if [[ -z "$version" ]]; then
    version=$(Rscript -e "source('/scripts/helpers.R');cat(cran_version('$package'))")
fi
url=$(Rscript -e "source('/scripts/helpers.R');cat(cran_source_url('$package', '$version'))")
echo "Downloading $url"
curl -LO $url

Rscript -e "remotes::install_deps('/${package}_${version}.tar.gz')"

mkdir binary && cd binary
R CMD INSTALL --build /${package}_${version}.tar.gz
mv * /packages/R-${R_VERSION}
```

------------------------------------------------------------------------

[The image at the top of this page is in the public domain](https://unsplash.com/photos/C0koz3G1I4I)

<div class="highlight">

<pre class='chroma'><code class='language-r' data-lang='r'><span class='nf'>devtools</span><span class='nf'>::</span><span class='nf'><a href='https://rdrr.io/pkg/sessioninfo/man/session_info.html'>session_info</a></span><span class='o'>(</span><span class='o'>)</span>
<span class='c'>#&gt; ─ Session info ───────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  setting  value                       </span>
<span class='c'>#&gt;  version  R version 4.0.3 (2020-10-10)</span>
<span class='c'>#&gt;  os       macOS Big Sur 10.16         </span>
<span class='c'>#&gt;  system   x86_64, darwin17.0          </span>
<span class='c'>#&gt;  ui       X11                         </span>
<span class='c'>#&gt;  language (EN)                        </span>
<span class='c'>#&gt;  collate  en_AU.UTF-8                 </span>
<span class='c'>#&gt;  ctype    en_AU.UTF-8                 </span>
<span class='c'>#&gt;  tz       Australia/Melbourne         </span>
<span class='c'>#&gt;  date     2021-04-19                  </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; ─ Packages ───────────────────────────────────────────────────────────────────</span>
<span class='c'>#&gt;  package     * version    date       lib source                            </span>
<span class='c'>#&gt;  callr         3.6.0      2021-03-28 [1] CRAN (R 4.0.3)                    </span>
<span class='c'>#&gt;  cli           2.4.0      2021-04-05 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  crayon        1.4.1      2021-02-08 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  desc          1.3.0      2021-03-05 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  devtools      2.3.2      2020-09-18 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  digest        0.6.27     2020-10-24 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  downlit       0.2.1      2020-11-04 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  ellipsis      0.3.1      2020-05-15 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  evaluate      0.14       2019-05-28 [1] CRAN (R 4.0.1)                    </span>
<span class='c'>#&gt;  fansi         0.4.2      2021-01-15 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  fs            1.5.0      2020-07-31 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  glue          1.4.2      2020-08-27 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  htmltools     0.5.1.1    2021-01-22 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  hugodown      0.0.0.9000 2021-04-19 [1] Github (r-lib/hugodown@97ea0cd)   </span>
<span class='c'>#&gt;  knitr         1.32       2021-04-14 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  lifecycle     1.0.0      2021-02-15 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  magrittr      2.0.1      2020-11-17 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  memoise       1.1.0      2017-04-21 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  pkgbuild      1.2.0      2020-12-15 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  pkgload       1.1.0      2020-05-29 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  prettyunits   1.1.1      2020-01-24 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  processx      3.5.1      2021-04-04 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  ps            1.6.0      2021-02-28 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  purrr         0.3.4      2020-04-17 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  R6            2.5.0      2020-10-28 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  remotes       2.2.0      2020-07-21 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  rlang         0.4.10     2020-12-30 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  rmarkdown     2.7.10     2021-04-19 [1] Github (rstudio/rmarkdown@eb55b2e)</span>
<span class='c'>#&gt;  rprojroot     2.0.2      2020-11-15 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  sessioninfo   1.1.1      2018-11-05 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  stringi       1.5.3      2020-09-09 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  stringr       1.4.0      2019-02-10 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  testthat      3.0.1      2020-12-17 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  usethis       2.0.1      2021-02-10 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  vctrs         0.3.7      2021-03-29 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  withr         2.4.2      2021-04-18 [1] CRAN (R 4.0.3)                    </span>
<span class='c'>#&gt;  xfun          0.22       2021-03-11 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt;  yaml          2.2.1      2020-02-01 [1] CRAN (R 4.0.2)                    </span>
<span class='c'>#&gt; </span>
<span class='c'>#&gt; [1] /Library/Frameworks/R.framework/Versions/4.0/Resources/library</span></code></pre>

</div>

