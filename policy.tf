# Policy Definition: Restrict to East US Locations
resource "azurerm_policy_definition" "policy" {
  name                = "onlydeployineastus"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "onlydeployineastus"
  management_group_id = var.tenant_id

  metadata = <<METADATA
{
  "category": "General"
}
METADATA

  policy_rule = <<POLICY_RULE
{
  "if": {
    "not": {
      "field": "location",
      "in": "[parameters('allowedLocations')]"
    }
  },
  "then": {
    "effect": "audit"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "type": "Array",
    "metadata": {
      "description": "The list of allowed locations for resources.",
      "displayName": "Allowed locations",
      "strongType": "location"
    },
    "defaultValue": ["westus2"],
    "allowedValues": [
      "eastus2",
      "westus2",
      "westus"
    ]
  }
}
PARAMETERS
}

# # Policy Definition: Restrict to West Europe
# resource "azurerm_policy_definition" "custom_restrict_location" {
#   name         = "only-allow-westeurope"
#   policy_type  = "Custom"
#   mode         = "All"
#   display_name = "Allow only West Europe location"

#   policy_rule = <<POLICY
# {
#   "if": {
#     "field": "location",
#     "notEquals": "westeurope"
#   },
#   "then": {
#     "effect": "deny"
#   }
# }
# POLICY
# }

resource "azurerm_policy_assignment" "restrict_location_sub" {
  name                 = "only-allow-westeurope-assignment"
  display_name         = "Restrict Location to US"
  policy_definition_id = azurerm_policy_definition.policy.id
  scope                = "/subscriptions/174655ab-4346-4b1d-90fb-2dfdeb60e5e8"
}
