variable "config" {
  description = "contains domain service configuration"
  type = object({
    name                      = string
    resource_group_name       = string
    location                  = string
    domain_name               = string
    domain_configuration_type = optional(string)
    sku                       = optional(string, "Standard")
    filtered_sync_enabled     = optional(bool)
    tags                      = optional(map(string))
    service_principal = optional(object({
      use_existing                  = optional(bool)
      other_cloud                   = optional(bool, false)
      account_enabled               = optional(bool)
      alternative_names             = optional(set(string))
      app_role_assignment_required  = optional(bool)
      description                   = optional(string)
      login_url                     = optional(string)
      notes                         = optional(string)
      notification_email_addresses  = optional(set(string))
      owners                        = optional(set(string))
      preferred_single_sign_on_mode = optional(string)
      tags                          = optional(set(string))
      feature_tags = optional(list(object({
        custom_single_sign_on = optional(bool)
        enterprise            = optional(bool)
        gallery               = optional(bool)
        hide                  = optional(bool)
      })), [])
      features = optional(list(object({
        custom_single_sign_on_app = optional(bool)
        enterprise_application    = optional(bool)
        gallery_application       = optional(bool)
        visible_to_users          = optional(bool)
      })), [])
      saml_single_sign_on = optional(object({
        relay_state = optional(string)
      }))
    }), {})
    initial_replica_set = object({
      subnet_id = string
    })
    notifications = optional(object({
      additional_recipients = optional(list(string), [])
      notify_dc_admins      = optional(bool, true)
      notify_global_admins  = optional(bool, true)
    }))
    secure_ldap = optional(object({
      enabled                  = bool
      pfx_certificate          = string
      pfx_certificate_password = string
      external_access_enabled  = optional(bool)
    }))
    security = optional(object({
      sync_kerberos_passwords         = optional(bool)
      sync_ntlm_passwords             = optional(bool)
      sync_on_prem_passwords          = optional(bool)
      ntlm_v1_enabled                 = optional(bool)
      tls_v1_enabled                  = optional(bool)
      kerberos_rc4_encryption_enabled = optional(bool)
      kerberos_armoring_enabled       = optional(bool)
    }))
    replica_sets = optional(map(object({
      location  = optional(string)
      subnet_id = string
    })), {})
    trusts = optional(map(object({
      name                   = optional(string)
      trusted_domain_fqdn    = string
      trusted_domain_dns_ips = list(string)
      password               = string
    })), {})
  })
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
