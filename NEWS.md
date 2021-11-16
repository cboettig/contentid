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
