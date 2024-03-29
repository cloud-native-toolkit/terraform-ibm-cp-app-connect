variable "catalog_name" {
  type        = string
  description = "The name of the Cloud Pak catalog"
  default     = "ibm-operator-catalog"
}

variable "cluster_type" {
  type        = string
  description = "The type of cluster"
  default     = "ocp4"
}

variable "cluster_config_file" {
  type        = string
  description = "The location of the kube config"
}

variable "namespace" {
  type        = string
  description = "The namespace where the platform navigator should be installed"
  default     = "cp4i"
}

variable "storage_class" {
  type        = string
  description = "The storage class that should be used for the dashboard and designer"
  default     = ""
}

variable "platform-navigator-name" {
  type        = string
  description = "The name of the platform navigator instance"
  default     = ""
}

variable "gitops_dir" {
  type        = string
  description = "The directory where the gitops configuration should be stored"
  default     = ""
}

variable "dashboard" {
  type        = bool
  description = "Flag to install the dashboard"
  default     = true
}

variable "channel" {
  type        = string
  description = "The channel from which the App Connect instance will be deployed"
  default     = "v1.5"
}

variable "license" {
  type        = string
  description = "The license key that should be applied"
  default     = "L-KSBM-BZWEAT"
}
