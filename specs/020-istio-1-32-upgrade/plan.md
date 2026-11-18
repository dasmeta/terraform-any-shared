# Plan

1. Update the chart repository and default version.
2. Align README defaults, explicit image overrides, and direct archive examples.
3. Document the two-stage in-place upgrade and verification steps; link it from defaults and examples.
4. Run Terraform formatting and validation, and scan every changed/new file for non-public details.

Use official Istio documentation for upgrade rules. Validation must not require a cluster connection or publish deployment-specific details.
