% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pin.R
\name{pin}
\alias{pin}
\title{Access the latest content at a URL (DEPRECATED)}
\usage{
pin(
  url,
  verify = TRUE,
  dir = content_dir(),
  registries = "https://hash-archive.org"
)
}
\arguments{
\item{url}{a URL to a web resource}

\item{verify}{logical, default TRUE. Should we verify the content identifier (SHA-256 hash)
of content at the URL before we look for a local cache?}

\item{dir}{path to the local store directory. Defaults to first local registry given to
the \code{registries} argument.}

\item{registries}{list of registries at which to register the URL}
}
\description{
This will download the requested object to a local cache and return the local path of the
object.  first time it is run, and then use a local cache
unless content has changed. This behavior is similar to \code{pins::pin()},
but uses cryptographic content hashes. Because content hashes are computed in a fast public
content registry, this will usually be faster than downloading on a local connection,
but slower than checking eTags in headers.  Use \link{resolve}
}
\details{
at this time, verify mode cannot process FTP resources.
Use verify = FALSE to enable a fast read from cache. This essentially allows
a URL to act as an identifier, and is a good choice for URLs known to be version
stable.  If verify = FALSE, this will merely attempt to find a local copy of data
previously associated (registered) at that URL. It will not attempt
to compute the content identifier of the content at the URL, thus the
local copy may or may not match the content at that address.
}
\seealso{
resolve
}
