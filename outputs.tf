output "id" {
  description = "Fully-qualified instance ID (projects/.../zones/.../instances/...)."
  value       = google_compute_instance.this.id
}

output "instance_id" {
  description = "Numeric server-assigned instance ID."
  value       = google_compute_instance.this.instance_id
}

output "name" {
  description = "Instance name."
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "Self link of the instance."
  value       = google_compute_instance.this.self_link
}

output "zone" {
  description = "Zone the instance runs in."
  value       = google_compute_instance.this.zone
}

output "internal_ip" {
  description = "Primary internal IP address of the instance."
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "external_ip" {
  description = "External IP address, or null when the instance has no public IP."
  value       = try(google_compute_instance.this.network_interface[0].access_config[0].nat_ip, null)
}
