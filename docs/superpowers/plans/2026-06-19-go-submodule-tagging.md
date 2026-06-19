# Go Submodule Tagging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `ship-it-bbs` push both `v{version}` and `models/v{version}` git tags, and make the pattern generic for any future package with Go submodules.

**Architecture:** Add a `go_submodule_dirs` opt-in field to `index.yml` package entries (same pattern as `on_windows`, `configure_db`). A new ytt helper returns the list (or `[]`). The `ship-it` loop in the pipeline template emits an extra `put` per submodule dir with a `{dir}/v` tag prefix.

**Tech Stack:** ytt (Carvel), Concourse CI, YAML

## Global Constraints

- Working directory: `~/workspace/wg-app-platform-runtime-ci`
- `ytt` must be on PATH (`which ytt` should succeed)
- All ytt templates must render without error after every task
- Follow existing `hasattr`-based opt-in pattern in `shared/helpers/ytt-helpers.star`
- Do NOT add `only_tag: true` to the github-release put — that step stays unchanged
- The loop must appear AFTER the `v` tag put and BEFORE the github-release put

---

### Task 1: Add `go_submodule_dirs` helper to ytt-helpers.star

**Files:**
- Modify: `shared/helpers/ytt-helpers.star`

**Interfaces:**
- Produces: `helpers.go_submodule_dirs(package)` — returns `package.go_submodule_dirs` (a list of strings) if the attribute exists, else `[]`

- [ ] **Step 1: Verify baseline ytt render passes**

```bash
cd ~/workspace/wg-app-platform-runtime-ci && ytt \
  -f wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml \
  -f wg-arp-diego-modules/index.yml \
  -f shared/helpers/ytt-helpers.star > /dev/null && echo "OK"
```

Expected output: `OK`

- [ ] **Step 2: Add the helper function to ytt-helpers.star**

Open `shared/helpers/ytt-helpers.star`. Add this function before the `helpers = struct.make(...)` line at the bottom:

```python
def go_submodule_dirs(package):
    if hasattr(package, "go_submodule_dirs"):
        return package.go_submodule_dirs
    end
    return []
end
```

Then add `go_submodule_dirs=go_submodule_dirs,` to the `struct.make(...)` call. The final struct call should look like:

```python
helpers = struct.make(
    packages_with_configure_db=packages_with_configure_db,
    packages_without_configure_db=packages_without_configure_db,
    packages_with_a_git_repo=packages_with_a_git_repo,
    packages_names_array=packages_names_array,
    packages_names_array_without_acceptance=packages_names_array_without_acceptance,
    on_windows=on_windows,
    privileged=privileged,
    on_branch=on_branch,
    go_submodule_dirs=go_submodule_dirs,
)
```

- [ ] **Step 3: Verify ytt still renders cleanly**

```bash
cd ~/workspace/wg-app-platform-runtime-ci && ytt \
  -f wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml \
  -f wg-arp-diego-modules/index.yml \
  -f shared/helpers/ytt-helpers.star > /dev/null && echo "OK"
```

Expected output: `OK`

- [ ] **Step 4: Commit**

```bash
cd ~/workspace/wg-app-platform-runtime-ci && \
  git add shared/helpers/ytt-helpers.star && \
  git commit -m "feat: add go_submodule_dirs helper to ytt-helpers"
```

---

### Task 2: Wire up go_submodule_dirs in index.yml and pipeline template

**Files:**
- Modify: `wg-arp-diego-modules/index.yml`
- Modify: `wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml`

**Interfaces:**
- Consumes: `helpers.go_submodule_dirs(package)` from Task 1

- [ ] **Step 1: Add go_submodule_dirs to the bbs entry in index.yml**

In `wg-arp-diego-modules/index.yml`, find the `bbs` entry (currently lines 56-58):

```yaml
- name: bbs
  repo: cloudfoundry/bbs
  configure_db: true
```

Change it to:

```yaml
- name: bbs
  repo: cloudfoundry/bbs
  configure_db: true
  go_submodule_dirs:
  - models
```

- [ ] **Step 2: Add the submodule tag loop to the pipeline ship-it job**

In `wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml`, find the `ship-it` job block (lines 339-369). The current block is:

```yaml
#@ for package in data.values.internal_repos:
- name: #@ "ship-it-{}".format(package.name)
  serial: true
  plan:
  - in_parallel:
      steps:
      - get: ci
      - get: #@ "{}-version".format(package.name)
      - resource: #@ package.name
        get: repo
        passed:
        - #@ package.name
        trigger: true
  - put: #@ package.name
    params:
      repository: repo
      tag: #@ "{}-version/number".format(package.name)
      tag_prefix: v
      only_tag: true
  - put: #@ "{}-github-release".format(package.name)
    params:
      name: #@ "{}-version/number".format(package.name)
      tag: #@ "{}-version/number".format(package.name)
      tag_prefix: v
  - get: next-version
    resource: #@ "{}-version".format(package.name)
    params: {bump: minor}
  - put: next-version
    resource: #@ "{}-version".format(package.name)
    params: {file: next-version/number}
#@ end
```

Replace it with (adding the `#@ for subdir` loop between the `v` tag put and the github-release put):

```yaml
#@ for package in data.values.internal_repos:
- name: #@ "ship-it-{}".format(package.name)
  serial: true
  plan:
  - in_parallel:
      steps:
      - get: ci
      - get: #@ "{}-version".format(package.name)
      - resource: #@ package.name
        get: repo
        passed:
        - #@ package.name
        trigger: true
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
    params:
      name: #@ "{}-version/number".format(package.name)
      tag: #@ "{}-version/number".format(package.name)
      tag_prefix: v
  - get: next-version
    resource: #@ "{}-version".format(package.name)
    params: {bump: minor}
  - put: next-version
    resource: #@ "{}-version".format(package.name)
    params: {file: next-version/number}
#@ end
```

- [ ] **Step 3: Verify rendered output for ship-it-bbs contains both tag puts**

```bash
cd ~/workspace/wg-app-platform-runtime-ci && ytt \
  -f wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml \
  -f wg-arp-diego-modules/index.yml \
  -f shared/helpers/ytt-helpers.star | grep -A40 "name: ship-it-bbs"
```

Expected output must include BOTH of these `put` blocks for `bbs`:
```yaml
  - put: bbs
    params:
      repository: repo
      tag: bbs-version/number
      tag_prefix: v
      only_tag: true
  - put: bbs
    params:
      repository: repo
      tag: bbs-version/number
      tag_prefix: models/v
      only_tag: true
```

- [ ] **Step 4: Verify a package WITHOUT go_submodule_dirs is unchanged**

```bash
cd ~/workspace/wg-app-platform-runtime-ci && ytt \
  -f wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml \
  -f wg-arp-diego-modules/index.yml \
  -f shared/helpers/ytt-helpers.star | grep -A40 "name: ship-it-lager"
```

Expected: only ONE `put: lager` block (with `tag_prefix: v`). No `models/v` block.

- [ ] **Step 5: Verify tag count for bbs ship-it is exactly 2 puts for bbs resource**

```bash
cd ~/workspace/wg-app-platform-runtime-ci && ytt \
  -f wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml \
  -f wg-arp-diego-modules/index.yml \
  -f shared/helpers/ytt-helpers.star | grep -A40 "name: ship-it-bbs" | grep -c "put: bbs"
```

Expected output: `2`

- [ ] **Step 6: Commit**

```bash
cd ~/workspace/wg-app-platform-runtime-ci && \
  git add wg-arp-diego-modules/index.yml wg-arp-diego-modules/pipelines/wg-arp-diego-modules.yml && \
  git commit -m "feat: tag bbs models/ Go submodule on ship-it"
```
