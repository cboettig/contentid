
<!-- README.md is generated from README.Rmd. Please edit that file -->

# contentid

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![CRAN
status](https://www.r-pkg.org/badges/version/contentid)](https://CRAN.R-project.org/package=contentid)
[![R build
status](https://github.com/cboettig/contentid/workflows/R-CMD-check/badge.svg)](https://github.com/cboettig/contentid/actions)
<!-- badges: end -->

`contentid` seeks to facilitate reproducible workflows that involve
external data files through the use of content identifiers.

## Quick start

Install the current development version using:

``` r
# install.packages("remotes")
remotes::install_github("cboettig/contentid")
```

``` r
library(contentid)
```

Instead of reading in data directly from a local file or URL, use
`register()` to register permanent content-based identifiers for your
external data file or URL:

``` r
register("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542")
#> [1] "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
```

Then, `resolve()` that content-based identifier in your scripts for more
reproducible workflow. Optionally, set `store=TRUE` to enable local
caching:

``` r
vostok <- resolve("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37",
                  store = TRUE)
```

`resolve` will download and cryptographically verify the identifier
matches the content, returning a local file path. Use that file path in
the of our analysis script, e.g. 

``` r
co2 <- read.table(vostok, 
                  col.names = c("depth", "age_ice", "age_air", "co2"), skip = 21)
```

------------------------------------------------------------------------

## Overview

R users frequently write scripts which must load data from an external
file – a step which increases friction in reuse and creates a common
failure point in reproducibility of the analysis later on. Reading a
file directly from a URL is often preferable, since we don’t have to
worry about distributing the data separately ourselves. For example, an
analysis might read in the famous CO2 ice core data directly from ORNL
repository:

``` r
co2 <- read.table("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542", 
                  col.names = c("depth", "age_ice", "age_air", "co2"), skip = 21)
```

However, we know that data hosted at a given URL could change or
disappear, and not all data we want to work with is available at a URL
to begin with. Digital Object Identifiers (DOIs) were created to deal
with these problems of ‘link rot’. Unfortunately, there is no straight
forward and general way to read data directly from a DOI, (which almost
always resolves to a human-readable webpage rather than the data
itself), often apply to collections of files rather than individual
source we want to read in our script, and we must frequently work with
data that does not (yet) have a DOI. Registering a DOI for a dataset has
gotten easier through repositories with simple APIs like Zenodo and
figshare, but this is still an involved process and still leaves us
without a mechanism to directly access the data. For instance, the data
referenced above has DOI <https://doi.org/10.3334/CDIAC/ATG.009>, but
this is still not easy to work directly into our R scripts.

`contentid` offers a complementary approach to addressing this
challenge, which will work with data that has (or will later receive) a
DOI, but also with arbitrary URLs or with local files. The basic idea is
quite similar to referencing data by DOI: we first “register” an
identifier, and then we use that identifier to retrieve the data in our
scripts:

``` r
register("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542")
#> [1] "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
```

Registering the data returns an identifier that we can `resolve` in our
scripts to later read in the file:

``` r
co2_file <- resolve("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
co2_b <- read.table(co2_file, 
                    col.names = c("depth", "age_ice", "age_air", "co2"), skip = 21)
```

Note that we have manually embedded the identifier in our script, rather
than automatically passing the identifier returned by `register()`
directly to resolve. The command to `register()` needs to only be run
once, and thus doesn’t need to be embedded in our script (though it is
harmless to include it, as it will always return the same identifier
unless the data file itself changes).

We can confirm this is the same data:

``` r
identical(co2, co2_b)
#> [1] TRUE
```

## How this works

As the identifier (`hash://sha256/...`) itself suggests, this is merely
the SHA-256 hash of the requested file. This means that unless the data
at that URL changes, we will always get that same identifier back when
we register that file. If we have a copy of that data someplace else, we
can verify it is indeed precisely the same data. For instance,
`contentid` includes a copy of this file as well. Registering the local
copy verifies that it indeed has the same hash:

``` r
co2_file_c <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
register(co2_file_c)
#> [1] "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
```

We have now registered the same content at two locations: a URL and a
local file path. `resolve()` will use this registry information to
access the requested content. `resolve()` will choose a local path
first, allowing us to avoid re-downloading any content we already have.
`resolve()` will verify the content of any local file or file downloaded
from a URL matches the requested content hash before returning the path.
If the file has been altered in any way, the hash will no longer match
and `resolve()` will try the next source.

We can get a better sense of this process by querying for all available
sources for our requested content:

``` r
sources("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#> # A tibble: 6 × 2
#>   source                                                     date               
#>   <chr>                                                      <dttm>             
#> 1 /home/cboettig/R/x86_64-pc-linux-gnu-library/4.1/contenti… 2021-10-18 04:34:00
#> 2 /tmp/RtmpQ2vwJM/sha256/94/12/9412325831dab22aeebdd674b6eb… 2021-10-18 04:33:59
#> 3 https://archive.softwareheritage.org/api/1/content/sha256… 2021-10-18 04:34:01
#> 4 https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-di… 2021-10-18 04:34:00
#> 5 https://zenodo.org/api/files/5967f986-b599-4492-9a08-94ce… 2021-10-18 04:22:27
#> 6 https://data.ess-dive.lbl.gov/catalog/d1/mn/v2/object/ess… 2021-10-06 05:43:31
```

Note that `sources()` has found more locations than we have registered
above. This is because in addition to maintaining a local registry of
sources, `contentid` registers online sources with the Hash Archive,
`https://hash-archive.org`. (The Hash Archive doesn’t store content, but
only a list of public links at which content matching the hash has been
seen.) `query_sources()` has also checked for this content on the
Software Heritage Archive, which does periodic crawls of all public
content on GitHub which have also picked up a copy of this exact file.
With each URL is a date at which it was last seen - repeated calls to
`register()` will update this date, or lead to a source being deprecated
for this content if the content it serves no longer matches the
requested hash. We can view the history of all registrations of a given
source using `history_url()`.

This approach can also be used with local or unpublished data.
`register()`ing a local file only creates an entry in `contentid`’s
local registry, so this does not provide a backup copy of the data or a
mechanism to distribute it to collaborators. But it does provide a check
that the data has not accidentally changed on our disk. If we move the
data or eventually publish the data, we have only to register these new
locations and we never need to update a script that accesses the data
using calls to `resolve()` like
`read.table(resolve("hash://sha256/xxx..."))` rather than using local
file names.

If we prefer to keep a local copy of a specific dataset around,
(e.g. for data that is used frequently or used across multiple
projects), we can instruct `resolve()` to store a persistent copy in
`contentid`’s local storage:

``` r
co2_file <- resolve("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37", 
                    store = TRUE)
```

Any future calls to `resolve()` with this hash on this machine will then
always be able to load the content from the local store. This provides a
convenient way to cache downloads for future use. Because the local
store is based on the content identifier, repeatedly storing the same
content will have no effect, and we cannot easily overwrite or
accidentally delete this content.

`register()` and `resolve()` provide a low-friction mechanism to create
a permanent identifier for external files and then resolve that
identifier to an appropriate source. This can be useful in scripts that
are frequently re-run as a way of caching the download step, and
simultaneously helps ensure the script is more reproducible. While this
approach is not fail-proof (since all registered locations could fail to
produce the content), if all else fails our script itself still contains
a cryptographic fingerprint of the data we could use to verify if a
given file was really the one used.

## Acknowledgements

`contentid` is largely based on the design and implementation of
`https://hash-archive.org`, and can interface with the
`https://hash-archive.org` API or mimic it locally. `contentid` also
draws inspiration from [Preston](https://github.com/bio-guoda/preston),
a biodiversity dataset tracker, and
[Elton](https://github.com/globalbioticinteractions/elton), a
command-line tool to update/clone, review and index existing species
interaction datasets.

This work is funded in part by grant [NSF OAC
1839201](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1839201&HistoricalAwards=false)
from the National Science Foundation.
