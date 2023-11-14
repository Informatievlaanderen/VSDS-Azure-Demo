resource "azurerm_resource_group" "res-0" {
  location = var.location
  name     = "ldes-client-demo"
}

resource "azurerm_log_analytics_workspace" "res-3" {
  location            = var.location
  name                = "workspace-ldesclientdemoFfxo"
  resource_group_name = azurerm_resource_group.res-0.name
}

resource "azurerm_container_app_environment" "res-2" {
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.res-3.id
  name                       = "ldioclientenv"
  resource_group_name        = azurerm_resource_group.res-0.name
  depends_on                 = [
    azurerm_storage_account.res-501
  ]
}

resource "azurerm_container_app" "res-1" {
  container_app_environment_id = azurerm_container_app_environment.res-2.id
  name                         = "ldio"
  resource_group_name          = azurerm_resource_group.res-0.name
  revision_mode                = "Single"
  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      cpu    = 0.5
      image  = "ghcr.io/informatievlaanderen/ldi-orchestrator:20230717135309"
      memory = "1Gi"
      name   = "ldio"
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_NAME"
        value = "ldes-cli"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_DESCRIPTION"
        value = "This pipeline uses an LDES client to read an existing LDES and writes the members out to Azure Blob"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_INPUT_NAME"
        value = "be.vlaanderen.informatievlaanderen.ldes.ldi.client.LdioLdesClient"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_INPUT_CONFIG_URL"
        value = var.ldes
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_INPUT_CONFIG_STATE"
        value = "postgres"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_INPUT_CONFIG_POSTGRES_URL"
        value = "jdbc:postgresql://${azurerm_postgresql_server.res-15.fqdn}:5432/postgres"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_INPUT_CONFIG_POSTGRES_USERNAME"
        value = "${azurerm_postgresql_server.res-15.administrator_login}@${azurerm_postgresql_server.res-15.name}"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_INPUT_CONFIG_POSTGRES_PASSWORD"
        value = azurerm_postgresql_server.res-15.administrator_login_password
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_INPUT_CONFIG_KEEPSTATE"
        value = "true"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_OUTPUTS_0_NAME"
        value = "be.vlaanderen.informatievlaanderen.ldes.ldio.LdiAzureBlobOut"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_OUTPUTS_0_CONFIG_LANG"
        value = "json"
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_OUTPUTS_0_CONFIG_STORAGEACCOUNTNAME"
        value = azurerm_storage_account.res-501.name
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_OUTPUTS_0_CONFIG_CONNECTIONSTRING"
        value = azurerm_storage_account.res-501.primary_connection_string
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_OUTPUTS_0_CONFIG_BLOBCONTAINER"
        value = azurerm_storage_data_lake_gen2_filesystem.example.name
      }
      env {
        name  = "ORCHESTRATOR_PIPELINES_0_OUTPUTS_0_CONFIG_JSONCONTEXTURI"
        value = "https://essentialcomplexity.eu/gipod.jsonld"
      }
    }
  }
  depends_on = [
    azurerm_storage_account.res-501,
    azurerm_storage_data_lake_gen2_filesystem.example,
    azurerm_role_assignment.example_role_assignment,
    azurerm_postgresql_firewall_rule.res-173
  ]
}

resource azurerm_storage_account "res-501" {
  account_replication_type = "RAGRS"
  account_tier             = "Standard"
  is_hns_enabled           = true
  location                 = var.location
  name                     = "demopowerquery"
  resource_group_name      = azurerm_resource_group.res-0.name
}
resource "azurerm_storage_data_lake_gen2_filesystem" "example" {
  name               = "example"
  storage_account_id = azurerm_storage_account.res-501.id
  depends_on         = [
    azurerm_storage_account.res-501
  ]
}
resource "azurerm_synapse_workspace" "res-507" {
  location                             = var.location
  name                                 = "synapseclient"
  resource_group_name                  = azurerm_resource_group.res-0.name
  sql_administrator_login              = "sqladminuser"
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.example.id
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_firewall_rule" "example" {
  name                 = "allowAll"
  synapse_workspace_id = azurerm_synapse_workspace.res-507.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

resource "azurerm_synapse_integration_runtime_azure" "example" {
  name                 = "example"
  synapse_workspace_id = azurerm_synapse_workspace.res-507.id
  location             = azurerm_resource_group.res-0.location
}

resource "azurerm_role_assignment" "example_role_assignment" {
  scope                = azurerm_storage_account.res-501.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.res-507.identity[0].principal_id
}

resource "azurerm_role_assignment" "example_role_assignment2" {
  scope                = azurerm_storage_account.res-501.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_principal_id
}

resource "azurerm_postgresql_server" "res-15" {
  auto_grow_enabled       = false
  location                = var.location
  name                    = "democlient"
  resource_group_name     = azurerm_resource_group.res-0.name
  sku_name                = "B_Gen5_1"
  administrator_login          = var.db_username
  administrator_login_password = var.db_password
  ssl_enforcement_enabled = true
  version                 = "11"
  depends_on              = [
    azurerm_resource_group.res-0,
  ]
}

resource "azurerm_postgresql_firewall_rule" "res-173" {
  end_ip_address      = "255.255.255.255"
  name                = "AllowAll_2023-7-17_12-4-31"
  resource_group_name = azurerm_resource_group.res-0.name
  server_name         = azurerm_postgresql_server.res-15.name
  start_ip_address    = "0.0.0.0"
  depends_on          = [
    azurerm_postgresql_server.res-15,
  ]
}