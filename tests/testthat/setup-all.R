
# sets the default application directory given by content_dir() to tempdir()
Sys.setenv("CONTENTID_HOME" = tempdir())

## Default registries when unset are given by default_registeries(),
## and loads both a local registry at content_dir(), and a remote registry
## at hash-archive.org. Here, we omit any remote registry by default,
## and set the local registry to the tempdir() location.
Sys.setenv("CONTENTID_REGISTRIES" = tempdir())

## Make sure we do not have alternate algos set
Sys.unsetenv("CONTENTID_ALGOS")


