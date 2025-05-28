# Define the resource group
resource "azurerm_resource_group" "demo_rg" {
  name     = "meetup-demo-rg"
  location = "westeurope"
}

# Create a virtual network and subnet for network rules demo
resource "azurerm_virtual_network" "demo_vnet" {
  name                = "meetup-demo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
}

resource "azurerm_subnet" "demo_subnet" {
  name                 = "meetup-demo-subnet"
  resource_group_name  = azurerm_resource_group.demo_rg.name
  virtual_network_name = azurerm_virtual_network.demo_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create the Azure Key Vault with network rules
resource "azurerm_key_vault" "demo_vault" {
  name                        = "meetupdemovault"
  location                    = azurerm_resource_group.demo_rg.location
  resource_group_name         = azurerm_resource_group.demo_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true

  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  # Network ACLs to restrict access
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
    virtual_network_subnet_ids = [azurerm_subnet.demo_subnet.id]
  }

  tags = {
    environment = "meetup-demo"
  }
}

# Grant the app registration access to the Key Vault
resource "azurerm_key_vault_access_policy" "app_access_policy" {
  key_vault_id = azurerm_key_vault.demo_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = "abdc857a-423e-4dda-a694-75a793f0ac56" # Object ID from the error

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

# First secret
resource "azurerm_key_vault_secret" "demo_secret" {
  name         = "demo-secret"
  value        = "SuperSecretValue123!"
  key_vault_id = azurerm_key_vault.demo_vault.id

  tags = {
    purpose = "meetup-demo"
  }
}

# Second secret for demo purposes
resource "azurerm_key_vault_secret" "demo_secret_2" {
  name         = "demo-secret-2"
  value        = "AnotherSecretValue456!"
  key_vault_id = azurerm_key_vault.demo_vault.id

  tags = {
    purpose = "meetup-demo"
  }
}

# Create a Log Analytics workspace for monitoring
resource "azurerm_log_analytics_workspace" "demo_law" {
  name                = "meetup-demo-law"
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Add diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "demo_diagnostic" {
  name                       = "meetup-demo-diagnostic"
  target_resource_id         = azurerm_key_vault.demo_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.demo_law.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

data "azurerm_client_config" "current" {}

# Custom role definition
resource "azurerm_role_definition" "demo_custom_role" {
  name        = "MeetupCustomRole"
  scope       = azurerm_resource_group.demo_rg.id
  description = "Custom role for meetup demo with limited Key Vault access"

  permissions {
    actions = [
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.KeyVault/vaults/secrets/read",
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.demo_rg.id,
  ]
}

# Role assignment
resource "azurerm_role_assignment" "demo_role_assignment" {
  scope              = azurerm_resource_group.demo_rg.id
  role_definition_id = azurerm_role_definition.demo_custom_role.role_definition_resource_id
  principal_id       = data.azurerm_client_config.current.object_id
}

# Policy definition to restrict location
resource "azurerm_policy_definition" "restrict_location" {
  name         = "restrict-to-westeurope"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Restrict to West Europe"

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "not": {
        "field": "location",
        "equals": "westeurope"
      }
    },
    "then": {
      "effect": "deny"
    }
  }
  POLICY_RULE
}

# Policy assignment
resource "azurerm_subscription_policy_assignment" "restrict_location_assignment" {
  name                 = "restrict-location-assignment"
  policy_definition_id = azurerm_policy_definition.restrict_location.id
  subscription_id      = "/subscriptions/174655ab-4346-4b1d-90fb-2dfdeb60e5e8"
}

# Output the Key Vault URI
output "key_vault_uri" {
  value = azurerm_key_vault.demo_vault.vault_uri
}
