resource "azurerm_policy_definition" "policy" {
  name                = "onlydeployineastus"
  policy_type         = "Custom"
  mode                = "All"
  display_name        = "onlydeployineastus"

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

resource "azurerm_policy_set_definition" "azurerm_policy_set_definition" {
  name         = "katestPolicySet"
  policy_type  = "Custom"
  display_name = "Test Policy Set"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.policy.id

    parameter_values = <<VALUE
{
  "allowedLocations": {
    "value": ["eastus2", "westus2"]
  }
}
VALUE
  }
}
