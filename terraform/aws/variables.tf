variable "mc_name" {
  description = "Management cluster name"
  default     = "default_mc"
}
variable "ssc_name" {
  description = "Shared services cluster name"
  default     = "default_ssc"
}
variable "wlc_name" {
  description = "Workload cluster name"
  default     = "default_wlc"
}
variable "aws_region" {
  description = "Aws Region"
  default     = "us-east-2"
}