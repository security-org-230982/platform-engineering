variable "region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type = string
}

variable "lock_table_name" {
  type    = string
  default = "platform-engineering-tf-locks"
}

variable "kms_alias" {
  type    = string
  default = "alias/platform-engineering-tf-state"
}
