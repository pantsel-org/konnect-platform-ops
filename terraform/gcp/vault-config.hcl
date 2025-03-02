storage "gcs" {
  bucket = "kpo-vault-storage"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

disable_mlock = true
ui            = true
