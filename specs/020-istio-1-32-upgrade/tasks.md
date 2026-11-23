# Tasks

- [x] Update defaults and examples to Istio 1.32.0 and the current repository.
- [x] Align documentation, including generated input defaults.
- [x] Document intermediate version pins, two separate applies, and rollout checks; link from defaults/examples.
- [x] Run `terraform fmt -check -recursive modules/istio` and `git diff --check`.
- [x] Validate the module and both changed examples without a cluster connection (zero errors/warnings).
- [x] Inspect all nine changed/new files for internal names, endpoints, accounts, paths, and credentials (no matches).
