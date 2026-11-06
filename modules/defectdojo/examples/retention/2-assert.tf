output "helm_metadata" {
  value       = module.defectdojo.helm_metadata
  description = "Application release metadata; retention is a separate companion release."

  precondition {
    condition     = module.defectdojo.helm_metadata[0].name == local.release_name
    error_message = "The optional retention release must preserve the application release identity."
  }
}
