# Preserve the historical controller state address when the legacy release
# became conditional. Removing this move makes a legacy upgrade replace an
# existing controller instead of retaining its Terraform state.
moved {
  from = helm_release.test
  to   = helm_release.legacy[0]
}
