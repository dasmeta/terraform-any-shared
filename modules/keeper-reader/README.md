### Keeper-Reader Module
This module is designed to read data from Keeper Security. Keeper stores various types of secrets. Currently, this module supports three types:
- Login
- SSH
- Database

To retrieve a secret value from each record, specify the UID and the record type. Ensure the `secret_type` is set appropriately:
Make sure the `secret_type` is
- Use `login` for Login record types.
- Use `ssh` for SSH record types.
- Use `db` for Database record types.

### Basic Usage Example
```
module "this" {
  source = "../../"

  secrets = [
    {
      secret_type = "ssh"
      uid         = "Q01idnfdzL9E61qh1Jb4pg"
    },
    {
      secret_type = "login"
      uid         = "zQpkIafNN-oAput14LhSVA"
    },
    {
      secret_type = "db"
      uid         = "MCibEDNanLDVsYvqlo3Ovw"
    },
  ]
  keeper_credentials = "/path/to/keeper/config.json"
}
```
