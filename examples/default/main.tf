module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.0.0.0/16"]
    dns_servers         = ["10.0.1.4", "10.0.1.5"]

    subnets = {
      aadds = {
        address_prefixes = ["10.0.1.0/24"]
        network_security_group = {
          name = "${module.naming.network_security_group.name}-aadds"
          rules = {
            AllowSyncWithAzureAD = {
              priority                   = 100
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "443"
              source_address_prefix      = "AzureActiveDirectoryDomainServices"
              destination_address_prefix = "*"
            }
            AllowPSRemoting = {
              priority                   = 200
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "5986"
              source_address_prefix      = "AzureActiveDirectoryDomainServices"
              destination_address_prefix = "*"
            }
            AllowRD = {
              priority                   = 201
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              source_port_range          = "*"
              destination_port_range     = "3389"
              source_address_prefix      = "CorpNetSaw"
              destination_address_prefix = "*"
            }
          }
        }
      }
    }
  }
}

module "domain_service" {
  source  = "codectl/ds/azuread"
  version = "~> 1.0"

  config = {
    name                      = "aadds-demo-dev"
    location                  = module.rg.groups.demo.location
    resource_group_name       = module.rg.groups.demo.name
    domain_name               = "example.com"
    sku                       = "Standard"
    domain_configuration_type = "FullySynced"

    initial_replica_set = {
      subnet_id = module.network.subnets.aadds.id
    }

    notifications = {
      notify_dc_admins     = true
      notify_global_admins = true
    }

    security = {
      sync_kerberos_passwords = true
    }
  }
}
