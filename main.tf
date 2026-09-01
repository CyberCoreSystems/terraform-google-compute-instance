# A single Compute Engine VM with the security posture hand-rolled instances
# routinely miss: Shielded VM (Secure Boot + vTPM + integrity monitoring) on by
# default, OS Login enabled, and NO external IP unless you explicitly opt in.
# Boots Debian 12 on a balanced persistent disk. Works with Terraform and
# OpenTofu.

locals {
  # OS Login is the recommended way to manage SSH access (IAM-driven, no
  # project-wide SSH keys), and project-wide SSH keys are additionally blocked
  # by default (defense in depth). Merge into any caller-supplied metadata; an
  # explicit metadata key always wins so callers can override.
  oslogin_metadata  = var.enable_oslogin ? { enable-oslogin = "TRUE" } : {}
  ssh_keys_metadata = var.block_project_ssh_keys ? { block-project-ssh-keys = "TRUE" } : {}
  metadata          = merge(local.oslogin_metadata, local.ssh_keys_metadata, var.metadata)
}

resource "google_compute_instance" "this" {
  # checkov:skip=CKV_GCP_38: disks are always encrypted at rest (Google-managed by default); CMEK is an explicit buyer knob via boot_disk_kms_key_self_link; CSEK raw keys are deliberately unsupported — key material must never transit a sold module's inputs
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type

  tags                      = var.tags
  labels                    = var.labels
  metadata                  = local.metadata
  metadata_startup_script   = var.metadata_startup_script
  can_ip_forward            = var.can_ip_forward
  deletion_protection       = var.deletion_protection
  allow_stopping_for_update = var.allow_stopping_for_update

  boot_disk {
    auto_delete = var.boot_disk_auto_delete

    # CMEK: encrypt the boot disk with a customer-managed Cloud KMS key. Null
    # (the default) keeps Google-managed encryption — disks are always
    # encrypted at rest either way.
    kms_key_self_link = var.boot_disk_kms_key_self_link

    initialize_params {
      image  = var.image
      size   = var.boot_disk_size_gb
      type   = var.boot_disk_type
      labels = var.labels
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    network_ip = var.network_ip

    # No access_config block => no external IP. Egress to the internet then
    # requires Cloud NAT. Opt into a public IP only when you truly need one.
    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        nat_ip       = var.public_ip_address
        network_tier = var.public_ip_network_tier
      }
    }
  }

  # Shielded VM: verifiable boot integrity. On by default; Debian 12 is a
  # UEFI/Shielded-compatible image.
  shielded_instance_config {
    enable_secure_boot          = var.enable_secure_boot
    enable_vtpm                 = var.enable_vtpm
    enable_integrity_monitoring = var.enable_integrity_monitoring
  }

  # Attach a custom service account with scoped access. When null the instance
  # uses the project's default compute service account.
  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [var.service_account]
    content {
      email  = service_account.value.email
      scopes = service_account.value.scopes
    }
  }
}
