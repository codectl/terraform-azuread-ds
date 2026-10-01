resource "azuread_service_principal" "this" {
  client_id                     = var.config.service_principal.other_cloud ? "6ba9a5d4-8456-4118-b521-9c5ca10cdf84" : "2565bd9d-da50-47d4-8b85-4c97f669dc36"
  use_existing                  = var.config.service_principal.use_existing
  account_enabled               = var.config.service_principal.account_enabled
  alternative_names             = var.config.service_principal.alternative_names
  app_role_assignment_required  = var.config.service_principal.app_role_assignment_required
  description                   = var.config.service_principal.description
  login_url                     = var.config.service_principal.login_url
  notes                         = var.config.service_principal.notes
  notification_email_addresses  = var.config.service_principal.notification_email_addresses
  owners                        = var.config.service_principal.owners
  preferred_single_sign_on_mode = var.config.service_principal.preferred_single_sign_on_mode
  tags                          = var.config.service_principal.tags

  dynamic "feature_tags" {
    for_each = var.config.service_principal.feature_tags

    content {
      custom_single_sign_on = feature_tags.value.custom_single_sign_on
      enterprise            = feature_tags.value.enterprise
      gallery               = feature_tags.value.gallery
      hide                  = feature_tags.value.hide
    }
  }

  dynamic "features" {
    for_each = var.config.service_principal.features

    content {
      custom_single_sign_on_app = features.value.custom_single_sign_on_app
      enterprise_application    = features.value.enterprise_application
      gallery_application       = features.value.gallery_application
      visible_to_users          = features.value.visible_to_users
    }
  }

  dynamic "saml_single_sign_on" {
    for_each = var.config.service_principal.saml_single_sign_on != null ? { this = var.config.service_principal.saml_single_sign_on } : {}

    content {
      relay_state = saml_single_sign_on.value.relay_state
    }
  }
}

resource "azurerm_active_directory_domain_service" "this" {
  depends_on = [azuread_service_principal.this]

  name                      = var.config.name
  location                  = var.config.location
  resource_group_name       = var.config.resource_group_name
  domain_name               = var.config.domain_name
  sku                       = var.config.sku
  filtered_sync_enabled     = var.config.filtered_sync_enabled
  domain_configuration_type = var.config.domain_configuration_type

  initial_replica_set {
    subnet_id = var.config.initial_replica_set.subnet_id
  }

  dynamic "notifications" {
    for_each = var.config.notifications != null ? { this = var.config.notifications } : {}

    content {
      additional_recipients = notifications.value.additional_recipients
      notify_dc_admins      = notifications.value.notify_dc_admins
      notify_global_admins  = notifications.value.notify_global_admins
    }
  }

  dynamic "secure_ldap" {
    for_each = var.config.secure_ldap != null ? { this = var.config.secure_ldap } : {}

    content {
      enabled                  = secure_ldap.value.enabled
      pfx_certificate          = secure_ldap.value.pfx_certificate
      pfx_certificate_password = secure_ldap.value.pfx_certificate_password
      external_access_enabled  = secure_ldap.value.external_access_enabled
    }
  }

  dynamic "security" {
    for_each = var.config.security != null ? { this = var.config.security } : {}

    content {
      sync_kerberos_passwords         = security.value.sync_kerberos_passwords
      sync_ntlm_passwords             = security.value.sync_ntlm_passwords
      sync_on_prem_passwords          = security.value.sync_on_prem_passwords
      ntlm_v1_enabled                 = security.value.ntlm_v1_enabled
      tls_v1_enabled                  = security.value.tls_v1_enabled
      kerberos_rc4_encryption_enabled = security.value.kerberos_rc4_encryption_enabled
      kerberos_armoring_enabled       = security.value.kerberos_armoring_enabled
    }
  }

  tags = coalesce(
    var.config.tags, var.tags
  )
}

resource "azurerm_active_directory_domain_service_replica_set" "this" {
  for_each = var.config.replica_sets

  domain_service_id = azurerm_active_directory_domain_service.this.id
  subnet_id         = each.value.subnet_id

  location = coalesce(
    each.value.location, azurerm_active_directory_domain_service.this.location
  )
}

resource "azurerm_active_directory_domain_service_trust" "this" {
  for_each = var.config.trusts

  name = coalesce(
    each.value.name, each.key
  )

  domain_service_id      = azurerm_active_directory_domain_service.this.id
  trusted_domain_fqdn    = each.value.trusted_domain_fqdn
  trusted_domain_dns_ips = each.value.trusted_domain_dns_ips
  password               = each.value.password
}
