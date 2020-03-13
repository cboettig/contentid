
<!-- README.md is generated from README.Rmd. Please edit that file -->

# contenturi

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/contenturi)](https://CRAN.R-project.org/package=contenturi)
[![R build
status](https://github.com/cboettig/contenturi/workflows/R-CMD-check/badge.svg)](https://github.com/cboettig/contenturi/actions)
<!-- badges: end -->

`contenturi` seeks to make it easy to adopt data workflows that are
based around the [hash-uri
specification](https://github.com/hash-uri/hash-uri) for
content-addressable storage. This very simple idea can be used to
address several challenging problems in data management.

The design and implementation of `contenturi` draws from
[Preston](https://github.com/bio-guoda/preston), a biodiversity dataset
tracker, and [Elton](https://github.com/globalbioticinteractions/elton),
a command-line tool to update/clone, review and index existing species
interaction datasets.

``` r
remotes::install_github("cboettig/contenturi")
```

``` r
library(contenturi)
```

Consider a classic dataset, in this case, the Vostok ice core data
analyzed by [Barnola et al
(1987)](https://doi.org/10.1038/329408a0 "Barnola, J., Raynaud, D., Korotkevich, Y. et al. Vostok ice core provides 160,000-year record of atmospheric CO2. Nature 329, 408–414 (1987)").
For convenience, a copy of the data is included in this package. Let’s
take a peak at the data
now:

``` r
vostok_co2 <- system.file("extdata", "vostok.icecore.co2", package = "contenturi")
readLines(vostok_co2, n = 10)
#>  [1] "*******************************************************************************"
#>  [2] "*** Historical CO2 Record from the Vostok Ice Core                          ***"
#>  [3] "***                                                                         ***"
#>  [4] "*** Source: J.M. Barnola                                                    ***"
#>  [5] "***         D. Raynaud                                                      ***"
#>  [6] "***         C. Lorius                                                       ***"
#>  [7] "***         Laboratoire de Glaciologie et de Geophysique de l'Environnement ***"
#>  [8] "***         38402 Saint Martin d'Heres Cedex, France                        ***"
#>  [9] "***                                                                         ***"
#> [10] "***         N. I. Barkov                                                    ***"
```

We aren’t concerned with parsing this data into R, we merely want an
identifier we can use to refer to this data. It has not been assigned a
DOI, to my knowledge, but we can easily compute a unique identifier
under the hash uri scheme:

``` r
content_uri(vostok_co2)
#> [1] "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
```

This identifier leverages the familiar URI format of other identifiers,
indicating the hash of the file content as well as the algorithm
(sha256) used to compute it. Unlike other content-addressable data
storage approaches (e.g., `dat`, IPFS, see
<https://github.com/hash-uri/hash-uri> for details), this identifier
contains no additional information beyond the content itself and is thus
agnostic of specific software implementation or storage system.

Frequently we access data resources from the internet instead. For
instance, the file in question was downloaded from
<http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2>. We can
download this file locally and confirm it creates the same identifier
(equivalent to comparing the file checksum, but using the checksum as
the identifier makes it harder to overlook this step\!). `contenturi`
can also let us register the URL at which we found the data in a hash
archive, <https://hash-archive.org>.

``` r
# Oh no, the official version is 503 errors.  Lets use this backup
co2_url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
register(co2_url)
#> [1] "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
```

Note that upon registering the URL, hash-archive.org has returned the
very same identifier, confirming this is the same content as our local
copy. Such an archive is nothing more than a simple key-value store,
indicating which URL(s) contain our content. In this way, it can act
much like a DOI re-direct, turing our identifier into resolvable,
downloadable URL. Unlike the DOI system though, this system is
completely distributed – we need not rely on any single authority to
issue the identifier, and we need not resolve the identifier to a single
location. Thanks to the cryptographic properties of the hash, it is
effectively impossible to generate a different identifier for the same
content, or the same identifier for different content. We need not trust
the authority of the registry, because we can always verify the content
we receive corresponds to what we wanted by comparing hashes (or hash
URIs).

``` r
query("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#> # A tibble: 24 x 3
#>    identifier                     source                     date               
#>    <chr>                          <chr>                      <dttm>             
#>  1 hash://sha256/9412325831dab22… https://archive.softwareh… 2020-03-05 06:30:33
#>  2 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-03-04 20:40:40
#>  3 hash://sha256/9412325831dab22… http://cdiac.ornl.gov/ftp… 2020-03-04 18:22:21
#>  4 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-03-03 04:00:26
#>  5 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-03-02 00:14:21
#>  6 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-29 20:16:09
#>  7 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-28 20:12:54
#>  8 hash://sha256/9412325831dab22… http://cdiac.ornl.gov/ftp… 2020-02-28 01:59:29
#>  9 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-26 19:16:18
#> 10 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-24 23:07:17
#> # … with 14 more rows
```

In this case, we see more than one URL has been registered containing
exactly the same content. That is not surprising, as this dataset is
commonly used and reproduced. Additional useful metadata, such as the
file size and time-stamp the URL was registered are also reported.
Notably, multiple URLs for an object could serve different purposes: we
could register URLs that are more susceptible to link rot in the long
term but provide higher bandwidth for downloads in the short term
(e.g. S3 bucket vs scientific repository.)

It is worth noting that we still have no guarantee that these urls will
not suffer link rot and cease to work – this is not a replacement for
archival storage efforts – but the hash URI identifier allows us to
avoid relying on a single storage point, and gives us a robust way to
refer to an object.

## Local Registries & Local Storage

We can also store and register content locally following this same
scheme.

``` r
store(co2_url)
#> [1] "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
```

Now when we query for the hash, we see a local storage location as
well:

``` r
query("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#> # A tibble: 25 x 3
#>    identifier                     source                     date               
#>    <chr>                          <chr>                      <dttm>             
#>  1 hash://sha256/9412325831dab22… https://archive.softwareh… 2020-03-05 06:30:33
#>  2 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-03-04 20:40:40
#>  3 hash://sha256/9412325831dab22… http://cdiac.ornl.gov/ftp… 2020-03-04 18:22:21
#>  4 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-03-03 04:00:26
#>  5 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-03-02 00:14:21
#>  6 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-29 20:16:09
#>  7 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-28 20:12:54
#>  8 hash://sha256/9412325831dab22… http://cdiac.ornl.gov/ftp… 2020-02-28 01:59:29
#>  9 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-26 19:16:18
#> 10 hash://sha256/9412325831dab22… https://zenodo.org/record… 2020-02-24 23:07:17
#> # … with 15 more rows
```

The `resolve()` verb (subject to change), provides a wrapper around
`query` that ‘resolves’ the content identifier to the content. It will
check for a locally stored copy of the content first, and download (and
verify) remote content
otherwise:

``` r
path <- resolve("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
```

Let’s take a peak at the returned copy:

``` r
readLines(path, n = 10)
#>  [1] "*******************************************************************************"
#>  [2] "*** Historical CO2 Record from the Vostok Ice Core                          ***"
#>  [3] "***                                                                         ***"
#>  [4] "*** Source: J.M. Barnola                                                    ***"
#>  [5] "***         D. Raynaud                                                      ***"
#>  [6] "***         C. Lorius                                                       ***"
#>  [7] "***         Laboratoire de Glaciologie et de Geophysique de l'Environnement ***"
#>  [8] "***         38402 Saint Martin d'Heres Cedex, France                        ***"
#>  [9] "***                                                                         ***"
#> [10] "***         N. I. Barkov                                                    ***"
```

## Programmatic long-term data access

One application of `contenturi` is to support robust access of data
files in R packages. One of the most common approaches remains the
distribution of data directly inside an R package, as in our example
above. This is not ideal for many reasons. However, packages that rely
on remote access of data risk link rot of those download URLs
(e.g. there is not a simple and universal mechanism for resolving
download URLs from DOIs, and many sources lack DOIs anyway). Such R
packages could instead register the current links in a hash archive,
allowing package or analysis code to refer directly to the hash uri
rather than a link that might rot. (Clearly this resolving step still
depends on the existence of some robust hash archive, a role scientific
repositories could easily fill. Note the hash archive is merely a
look-up table, it does not need to store any actual content).

## Comparison to DOIs and other location-based identifiers

Most identifiers, such as DOIs, EZIDs, PURLs, etc are location-based. At
the heart of such identifiers is the notion of an HTTP redirect, where
the DOI or other identifier resolves to a different URL. This allows
researchers to consistently resolve the same content even if the
location (or at least the internet address) of the data changes.

Content URIs are completely compatible with such location-based
identifiers, indeed, there is no reason why such an identifier could not
be the (or one of the) download URLs resolved by the content identifier.
I think it would be ideal if data repositories such as Zenodo, Dryad, or
institutional repositories, which together offer some of our best
capacity for archival storage, would register the locations of their
content by such content hash URIs.
