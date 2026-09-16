# buildkit-builders

Long-lived rootless BuildKit builders, one per architecture, for CI jobs to
attach to.

One per architecture, which is the common case:

```hcl
module "builders" {
  source = "git::.../modules/k8s/buildkit-builders?ref=vX.Y.Z"

  namespace          = "buildkit"
  architectures      = ["amd64", "arm64"]
  name_prefix        = "shared"
  storage_class_name = "block-storage"
}
```

Produces builders `shared-amd64` and `shared-arm64`, as StatefulSets
`shared-amd640` and `shared-arm640` — buildx appends `0` to a builder name —
each with its own PVC.

Or name them yourself, which is what you want when adopting builders that
already exist:

```hcl
  builders = {
    "sarah-arm64" = {
      node_selector = { "kubernetes.io/arch" = "arm64" }
      labels        = { "app.kubernetes.io/part-of" = "sarah" }
    }
  }
```

**Keep a name identical when adopting one.** The state PVC is derived from the
StatefulSet name (`state-<name>-0`), so an unchanged name reuses the existing
cache. Renaming starts cold.

## Why declare them instead of letting buildx create them

`docker/setup-buildx-action` with the kubernetes driver will create a builder
for you, and for a throwaway per-job builder that is the right answer. For a
persistent one it is not: asked for a PVC it emits a StatefulSet with an empty
pod `securityContext`, so rootless BuildKit — running as uid 1000 — cannot take
the lock on a freshly provisioned, root-owned volume:

```
could not lock /home/user/.local/share/buildkit/buildkitd.lock
[rootlesskit:parent] error: child exited: exit status 1
```

The pod crashloops, and a job that asks for that builder fails with
`expected 1 replicas to be ready, got 0` before it runs a step. Setting
`fsGroup` is what makes the volume writable, and that is what this module is
for.

## Attaching from a workflow

```yaml
- uses: docker/setup-buildx-action@v4
  with:
    name: shared-arm64      # not the StatefulSet name
    cleanup: false          # a shared builder outlives the job
    driver: kubernetes
    driver-opts: |
      namespace=buildkit
      nodeselector=kubernetes.io/arch=arm64
      rootless=true
      image=moby/buildkit:v0.32.2-rootless
```

The cache then survives between runs and across repositories, and no job waits
for a builder pod to boot.

## Requirements

- The namespace must permit unconfined seccomp and AppArmor; rootless BuildKit
  nests containers. A PodSecurity level of `privileged` on that namespace, or an
  equivalent exemption.
- Block storage. The state volume is `ReadWriteOnce` — one writer per builder.
- Nodes of each architecture you ask for. Builders are pinned by
  `kubernetes.io/arch`; building for a platform on the wrong one means emulation.

## Cache size

`gc_max_used_space` must stay under `state_storage`, or the volume fills and
every build sharing that builder wedges. Defaults leave headroom (70GB of cache
on a 100GB volume).
