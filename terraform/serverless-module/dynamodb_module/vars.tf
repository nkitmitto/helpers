variable "dataSourceName" {
    type = string
    default = ""
}

variable "project_name" {
}

variable "environment" {
}

variable "hash_key" {
}

variable "attributes" {
  type        = list(map(string))
  default     = []
}