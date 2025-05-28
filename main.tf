resource "azurerm_resource_group" "demo_rg" {
  name     = "meetup-demo-rg"
  location = "westeurope"
}

# Tworzenie Azure Key Vault
resource "azurerm_key_vault" "demo_vault" {
  name                        = "meetupdemovault"
  location                    = azurerm_resource_group.demo_rg.location
  resource_group_name         = azurerm_resource_group.demo_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true

  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  tags = {
    environment = "meetup-demo"
  }
}

resource "azurerm_key_vault_secret" "demo_secret" {
  name         = "demo-secret"
  value        = "SuperSecretValue123!"
  key_vault_id = azurerm_key_vault.demo_vault.id

  # Tagi dla sekretu
  tags = {
    purpose = "meetup-demo"
  }
}

data "azurerm_client_config" "current" {}

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

resource "azurerm_role_assignment" "demo_role_assignment" {
  scope              = azurerm_resource_group.demo_rg.id
  role_definition_id = azurerm_role_definition.demo_custom_role.role_definition_resource_id
  principal_id       = data.azurerm_client_config.current.object_id
}

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

resource "azurerm_subscription_policy_assignment" "restrict_location_assignment" {
  name                 = "restrict-location-assignment"
  policy_definition_id = azurerm_policy_definition.restrict_location.id
  subscription_id      = "/subscriptions/174655ab-4346-4b1d-90fb-2dfdeb60e5e8"
}

output "key_vault_uri" {
  value = azurerm_key_vault.demo_vault.vault_uri
}