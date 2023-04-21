# contentid 0.0.17

- bugfix for Zenodo resolver to search all versions

- bugfix for local cache / content store handling of hashes other than SHA-256

- software heritage is no longer a default registry. SWH imposes rate
  limiting of 120 calls, and so should not be pinged if not expected as a registry.

- a new function, `swh_ratelimit()`, can show the remaining available calls and
  the remaining time until rate limit is incremented (rate limit resets gradually.)
  Users may use this new function when explicitly working against the SWH API
  to program their own retry attempts appropriately.

- `purge_cache()` behavior improved.

# contentid 0.0.16

- official hash-archive is offline and no longer a default source.

# contentid 0.0.15

- minor performance-enhancements to `resolve()`

# contentid 0.0.14

- all donttest examples set temporary storage instead of trusting
  that CRAN is setting R_USER_DATA_DIR for `tools::R_user_dir()`
  to an appropriate setting for running donttest examples.
- Include an additional hash-archive-like registry in `default_registries()` 
  (https://hash-archive.carlboettiger.info)
- `default_registries()` is now an exported function.
- Some edits for robustness: `tsv-backed` registries disable `vroom` altrep,
(which can create file-lock issues on Windows. Even though altrep reading
can provide significant speed improvements in this context with a large
local registry, using LMDB for that case will still be much faster.)

- Minor adjustments to some function names:
  * `query_sources()` is now renamed `sources()`
  * `query_history()` is renamed `history_url()`
  * `query`, `query_sources()`, and ``query_history()` still present but 
     flagged for deprecation
  * `pin` still present but marked for deprecation

# contentid 0.0.12

* add `purge_cache()` to easily free space used by contentid

# contentid 0.0.11

* Increase speed of resolving files that are already local [#74]

# contentid 0.0.10

* more robust handling of URL error conditions

# contentid 0.0.9

* use base R tools instead of rappdirs, requires R >= 4.0

# contentid 0.0.8

* check for `vroom` quietly

# contentid 0.0.7

* support vector inputs for `store()` and `retrieve()`
* add intro vignette from README
* `content_id()` now returns a chr vector instead of a data.frame unless
  multiple algos are requested. 

# contentid 0.0.6

* Solaris has issues with LMDB size apparently

# contentid 0.0.5

* Avoid erroneously failures on CRAN during to network connectivity issues on CRAN machines

# contentid 0.0.4 2020-08-12

* Added a `NEWS.md` file to track changes to the package.
