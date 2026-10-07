variable "bucket_name" {
  description = "Name of the new or imported IDrive e2 bucket."
  type        = string
}

variable "tags" {
  description = "Bucket tags. Include existing tags when importing."
  type        = map(string)
  default     = {}
}

variable "versioning_status" {
  description = "Enabled or Suspended; null leaves versioning unmanaged (new buckets are unversioned)."
  type        = string
  default     = null

  validation {
    condition     = var.versioning_status == null ? true : contains(["Enabled", "Suspended"], var.versioning_status)
    error_message = "versioning_status must be Enabled, Suspended, or null."
  }
}

variable "cleanup_rules" {
  description = "Rules keyed by lifecycle rule ID. Only deletes noncurrent versions and expired delete markers; never expires current objects. An empty map leaves lifecycle unmanaged."
  type = map(object({
    prefix          = optional(string, "")
    noncurrent_days = optional(number, 2)
  }))
  default = {}

  validation {
    condition = alltrue([
      for id, rule in var.cleanup_rules :
      length(id) > 0 && length(id) <= 255 &&
      rule.noncurrent_days >= 2 && floor(rule.noncurrent_days) == rule.noncurrent_days
    ])
    error_message = "Each rule needs an ID of 1–255 characters and an integer noncurrent_days of at least 2."
  }
}
