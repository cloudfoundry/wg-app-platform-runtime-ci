# CachedDownloader

CachedDownloader is responsible for downloading and caching files and
maintaining reference counts for each cache entry. Entries in the cache with
no active references are ejected from the cache when new space is needed.

> [!NOTE]
>
> This repository should be imported as `code.cloudfoundry.org/cacheddownloader`.
