module "this" {
  source = "../../"

  secrets = [
    {
      secret_type = "login"
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
