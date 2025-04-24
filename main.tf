
resource "azurerm_key_vault" "keyvault" {
  name                        = local.kv_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = true
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = "SuperSecret123!"
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Reader"
  principal_id         = "00000000-0000-0000-0000-000000000000"
}

resource "azurerm_policy_definition" "custom_restrict_location" {
  name         = "only-allow-westeurope"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allow only West Europe location"
  policy_rule = <<POLICY
{
  "if": {
    "field": "location",
    "notEquals": "westeurope"
  },
  "then": {
    "effect": "deny"
  }
}
POLICY
}

resource "azurerm_policy_set_definition" "policy_initiative" {
  name         = "initiative-restrict-env"
  policy_type  = "Custom"
  display_name = "Restrict resources by environment"
  policy_definitions = [
    {
      policy_definition_id = azurerm_policy_definition.custom_restrict_location.id
    }
  ]
}

resource "azurerm_policy_assignment" "initiative_assignment" {
  name                 = "assign-initiative-restrict-env"
  scope                = azurerm_resource_group.rg.id
  policy_definition_id = azurerm_policy_set_definition.policy_initiative.id
}

resource "azurerm_management_group_policy_assignment" "mgmt_assignment" {
  name                 = "mgmt-assign-initiative"
  management_group_id  = "00000000-0000-0000-0000-000000000000"  # przykładowy ID
  policy_definition_id = azurerm_policy_set_definition.policy_initiative.id
}

resource "azurerm_role_definition" "Network_Reader" {
  name        = "Network_Reader"
  scope       = "/subscription/${var.subscription_id}"
  description = "Custom Network Reader, allowed to read all network resources"

  permissions {
    actions     = ["Microsoft.Network/*/read"]
    not_actions = []
  }

  assignable_scopes = [var.tenant_id]
}