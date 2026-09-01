variable "project_id" {
  description = "GCP project ID that hosts the instance."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid GCP project ID (6-30 chars, lowercase letters, digits, hyphens)."
  }
}

variable "name" {
  description = "Name of the Compute Engine instance (RFC1035: lowercase letters, digits, hyphens; must start with a letter)."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.name))
    error_message = "name must be 1-63 chars, start with a lowercase letter, and contain only lowercase letters, digits and hyphens."
  }
}

variable "zone" {
  description = "Zone to launch the instance in (e.g. us-central1-a). Null falls back to the provider's configured zone."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Machine type. e2-micro is the smallest/cheapest general-purpose shape."
  type        = string
  default     = "e2-micro"
}

variable "image" {
  description = "Boot disk image, as a family shorthand (project/family) or full self link. Defaults to Debian 12."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 10

  validation {
    condition     = var.boot_disk_size_gb >= 10 && var.boot_disk_size_gb <= 65536
    error_message = "boot_disk_size_gb must be between 10 and 65536."
  }
}

variable "boot_disk_type" {
  description = "Boot disk type: pd-standard, pd-balanced, pd-ssd or pd-extreme."
  type        = string
  default     = "pd-balanced"

  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd", "pd-extreme"], var.boot_disk_type)
    error_message = "boot_disk_type must be one of: pd-standard, pd-balanced, pd-ssd, pd-extreme."
  }
}

variable "boot_disk_auto_delete" {
  description = "Delete the boot disk when the instance is deleted."
  type        = bool
  default     = true
}

variable "boot_disk_kms_key_self_link" {
  description = "Self link of a Cloud KMS crypto key to encrypt the boot disk with (CMEK), e.g. projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY. Null keeps Google-managed encryption (disks are always encrypted at rest). The Compute Engine service agent needs roles/cloudkms.cryptoKeyEncrypterDecrypter on the key."
  type        = string
  default     = null

  validation {
    condition     = var.boot_disk_kms_key_self_link == null || can(regex("^(https://[a-z.]+/[a-z0-9]+/)?projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", var.boot_disk_kms_key_self_link))
    error_message = "boot_disk_kms_key_self_link must be null or a Cloud KMS crypto key path: projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY."
  }
}

variable "network" {
  description = "VPC network self link or name for the network interface. Optional when subnetwork is set (the network is inferred)."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Subnetwork self link or name for the network interface. Required for custom-mode VPCs."
  type        = string

  validation {
    condition     = length(var.subnetwork) > 0
    error_message = "subnetwork must be a non-empty subnetwork name or self link."
  }
}

variable "network_ip" {
  description = "Static internal IP for the instance. Null lets GCP allocate one from the subnet."
  type        = string
  default     = null
}

variable "enable_public_ip" {
  description = "Attach an ephemeral (or static) external IP. Off by default — keep instances private and use Cloud NAT for egress."
  type        = bool
  default     = false
}

variable "public_ip_address" {
  description = "Static external IP address to attach when enable_public_ip is true. Null = ephemeral IP."
  type        = string
  default     = null
}

variable "public_ip_network_tier" {
  description = "Network tier for the external IP: PREMIUM or STANDARD."
  type        = string
  default     = "PREMIUM"

  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.public_ip_network_tier)
    error_message = "public_ip_network_tier must be PREMIUM or STANDARD."
  }
}

variable "enable_secure_boot" {
  description = "Shielded VM: enable Secure Boot (verified boot chain)."
  type        = bool
  default     = true
}

variable "enable_vtpm" {
  description = "Shielded VM: enable the virtual Trusted Platform Module."
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Shielded VM: enable boot integrity monitoring."
  type        = bool
  default     = true
}

variable "enable_oslogin" {
  description = "Enable OS Login (IAM-managed SSH access) via instance metadata. Strongly preferred over project-wide SSH keys."
  type        = bool
  default     = true
}

variable "block_project_ssh_keys" {
  description = "Block project-wide SSH keys via instance metadata (block-project-ssh-keys). Defense in depth alongside OS Login; only instance-level keys/IAM grants can SSH."
  type        = bool
  default     = true
}

variable "service_account" {
  description = "Custom service account for the instance. Null uses the default compute service account. scopes accepts aliases (e.g. cloud-platform)."
  type = object({
    email  = string
    scopes = optional(list(string), ["cloud-platform"])
  })
  default = null
}

variable "tags" {
  description = "Network tags applied to the instance (used by firewall rule targeting)."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels applied to the instance and boot disk (lowercase keys/values per GCP label rules)."
  type        = map(string)
  default     = {}
}

variable "metadata" {
  description = "Instance metadata key/value pairs. Merged with the OS Login key (explicit keys here win)."
  type        = map(string)
  default     = {}
}

variable "metadata_startup_script" {
  description = "Startup script run on boot. Null = none."
  type        = string
  default     = null
}

variable "can_ip_forward" {
  description = "Allow the instance to send/receive packets with non-matching source/destination IPs (needed for NAT/router VMs)."
  type        = bool
  default     = false
}

variable "allow_stopping_for_update" {
  description = "Allow Terraform to stop the instance to apply updates that require it (e.g. machine type changes)."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protect the instance from accidental deletion. Set false to allow terraform destroy."
  type        = bool
  default     = true
}
