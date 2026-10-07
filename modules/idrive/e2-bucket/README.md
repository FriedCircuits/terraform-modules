# IDrive e2 bucket

Create or import a private bucket, optionally manage versioning, and clean up
noncurrent versions after at least two days. Cleanup also removes expired delete
markers. Current objects are not expired.
Nonempty buckets cannot be destroyed by this module.

## Usage

See [examples/basic/main.tf](examples/basic/main.tf) for the IDrive AWS provider
configuration. Keep the provider and credentials in your private root configuration;
the module inherits the provider. AWS provider 5.100 is the compatibility baseline.

```hcl
module "bucket" {
  source = "git::https://github.com/FriedCircuits/terraform-modules.git//modules/idrive/e2-bucket?ref=v1.8.0"

  bucket_name       = "example-data"
  versioning_status = "Enabled"
  cleanup_rules = {
    version-cleanup = {
      prefix          = "data/"
      noncurrent_days = 2
    }
  }
}
```

For an unversioned bucket, supply only `bucket_name`. Versioning and lifecycle
are left unmanaged. Use a separate module call per bucket. An empty prefix applies cleanup to the entire bucket.

| Input | Default | Purpose |
| --- | --- | --- |
| `bucket_name` | Required | New or existing bucket name |
| `tags` | `{}` | Bucket tags; include existing tags during import |
| `versioning_status` | `null` | `Enabled`, `Suspended`, or unmanaged |
| `cleanup_rules` | `{}` | Rule IDs mapped to `prefix` (default empty) and `noncurrent_days` (default 2) |

Output: `bucket_name`.

## Import existing buckets

Define the module with the existing bucket name and settings first, then run:

```sh
terraform import module.bucket.aws_s3_bucket.this example-data
terraform import 'module.bucket.aws_s3_bucket_versioning.this[0]' example-data
terraform import 'module.bucket.aws_s3_bucket_lifecycle_configuration.this[0]' example-data
terraform plan
```

Only import versioning/lifecycle when you configure those resources and they
already exist. When versioning and lifecycle are unmanaged, import only the bucket.

Match `tags`, `cleanup_rules` keys, and prefixes to the existing bucket and UI
settings before importing. Terraform owns the bucket's **entire lifecycle
configuration**: include every existing rule you want to retain. This module
supports only version cleanup; buckets with other lifecycle actions need a
different lifecycle configuration.

Removing all rules from the map after managing them destroys the managed lifecycle
configuration; it does not hand it back to the UI. Likewise, removing managed
versioning from configuration can suspend versioning. Use `terraform state rm`
to relinquish management without changing remote settings.

The expiration timer begins when an object becomes noncurrent, not when the rule is
created. Eligible older versions are permanently deleted during IDrive's background
processing. Suspending versioning does not remove existing old versions.

## Validation

```sh
terraform init -backend=false
terraform validate
terraform test
```

Tests use a mock provider and do not access IDrive.

The AWS-only lifecycle transition-size default is ignored because IDrive does
not expose it.

References: [IDrive lifecycle API](https://www.idrive.com/s3-storage-e2/s3-compatible-api),
[AWS provider lifecycle resource](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_bucket_lifecycle_configuration).
