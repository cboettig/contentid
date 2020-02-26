
# sets the default application directory given by app_dir() to tempdir()
Sys.setenv("CONTENTURI_HOME" = tempdir())

## Default registries when unset are given by default_registeries(), and loads both
## a local registry at app_dir(), and a remote registry at hash-archive.org
## Here, we omit any remote registry by default, and set the local registry to the tempdir() location.
Sys.setenv("CONTENTURI_REGISTRIES" = tempdir())
