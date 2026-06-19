# Go Submodule Tagging in wg-arp-diego-modules Pipeline

**Date:** 2026-06-19  
**Status:** Approved

## Problem

Go requires a subdirectory Go module (e.g. `code.cloudfoundry.org/bbs/models` at `bbs/models/go.mod`) to be tagged with a path-prefixed tag: `models/v1.1.0`, not just `v1.1.0`. Without that tag, the Go module proxy cannot resolve the module at any specific version — it falls back to a pseudo-version.

The `ship-it-{package}` jobs in `wg-arp-diego-modules` only push one tag (`v{version}`). `bbs` has a `models/` subdirectory with its own `go.mod` and no `models/v*` tags exist yet.

## Solution

Add a generic `go_submodule_dirs` field to package entries in `index.yml`. The `ship-it` ytt loop emits an additional `put` step per submodule dir, pushing `{dir}/v{version}` at the same commit.

## Changes

### 1. `wg-arp-diego-modules/index.yml`

Add `go_submodule_dirs` to the `bbs` entry:

```yaml
- name: bbs
  repo: cloudfoundry/bbs
  configure_db: true
  go_submodule_dirs:
  - models
```

Any future package with subdirectory Go modules just adds `go_submodule_dirs` to its entry — no pipeline template changes needed.

### 2. `shared/helpers/ytt-helpers.star`

New helper function, consistent with existing `on_windows` / `privileged` pattern:

```python
def go_submodule_dirs(package):
    if hasattr(package, "go_submodule_dirs"):
        return package.go_submodule_dirs
    end
    return []
end
```

Add to the `helpers = struct.make(...)` at the bottom of the file.

### 3. `wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml`

In the `ship-it` job loop, add a ytt loop after the main `v` tag put and before the github-release put:

```yaml
  - put: #@ package.name
    params:
      repository: repo
      tag: #@ "{}-version/number".format(package.name)
      tag_prefix: v
      only_tag: true
#@ for subdir in helpers.go_submodule_dirs(package):
  - put: #@ package.name
    params:
      repository: repo
      tag: #@ "{}-version/number".format(package.name)
      tag_prefix: #@ "{}/v".format(subdir)
      only_tag: true
#@ end
  - put: #@ "{}-github-release".format(package.name)
    ...
```

## Result

For `bbs` at version `1.1.0`, `ship-it-bbs` will push:
1. `v1.1.0` (existing)
2. `models/v1.1.0` (new)

Both at the same commit. The Go module proxy can now resolve `code.cloudfoundry.org/bbs/models` at a specific version.

## Scope

- Only `wg-arp-diego-modules` pipeline template needs updating (not networking/garden/volume-services, which have no repos with Go submodules today).
- The `go_submodule_dirs` helper lives in `shared/helpers/ytt-helpers.star` so other pipeline templates can adopt it without changes to the helper.
- No new shared tasks required.
