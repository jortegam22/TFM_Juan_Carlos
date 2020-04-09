## Application - Variables ##
# company name 
variable "asa_input_name" {
  type = string
  default = "eventhub"
}
# application name 
variable "asa_name" {
  type = string
  default = "prodEventsASA"
}
# application or company environment
variable "asa_output_name" {
  type = string
  default = "blob"
}
# azure region
variable "eh_name" {
  type = string
  default = "prodEventHub"
}
## Network - Variables ##
variable "ehcg_name" {
  type = string
  default = "$Default"
}
variable "ehns_access_policy_key" {
  type = string
  default = "FGXxScqQzjPNdooGWhVaKSf/GkXHHXous1vCU+T5Z3U="
}
variable "ehns_name" {
  type = string
  default = "prodEventHubNamespace"
}
# application or company environment
variable "post_ASA" {
  type = string
  default = "errors"
}
# azure region
variable "rg_location" {
  type = string
  default = "West Europe"
}
## Network - Variables ##
variable "rg_name" {
  type = string
  default = "Production"
}
variable "sa_key" {
  type = string
  default = "QzqmR76F0oFMCcJNk50c8vtVAVPP5Y2BhktuUDu6ZTv33wYlMk14qQL0TSE08KP9zMZs7ssaKhHrCZyPk5hJVg=="
}
variable "sa_name" {
  type = string
  default = "prodevents"
}
