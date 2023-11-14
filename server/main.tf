resource "azurerm_resource_group" "res-0" {
  location = var.location
  name     = "ldes-server"
}

resource "azurerm_log_analytics_workspace" "res-3" {
  location            = var.location
  name                = "workspace-ldes-server"
  resource_group_name = azurerm_resource_group.res-0.name
}

resource "azurerm_container_app_environment" "res-2" {
  location                   = var.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.res-3.id
  name                       = "ldes-server-env"
  resource_group_name        = azurerm_resource_group.res-0.name
}

resource "azurerm_container_app" "ldes-server" {
  container_app_environment_id = azurerm_container_app_environment.res-2.id
  name                         = "ldes-server"
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
      image  = "ldes/ldes-server:2.3.0-SNAPSHOT"
      memory = "1Gi"
      name   = "ldes-server"
      env {
        name  = "SPRINGDOC_SWAGGERUI_PATH"
        value = "/v1/swagger"
      }
      env {
        name  = "LDESSERVER_HOSTNAME"
        value = "localhost"
      }
      env {
        name = "SPRING_DATA_MONGODB_URI"
        value = replace(azurerm_cosmosdb_account.db.connection_strings[0],"?", "${azurerm_cosmosdb_mongo_database.mongodb.name}?")
      }
      /*
      env {
        name  = "SPRING_DATA_MONGODB_HOST"
        value = azurerm_cosmosdb_mongo_database.mongodb.connection.host
      }
      env {
        name  = "SPRING_DATA_MONGODB_PORT"
        value = azurerm_cosmosdb_mongo_database.mongodb.connection.port
      }
      env {
        name  = "SPRING_DATA_MONGODB_DATABASE"
        value = azurerm_cosmosdb_mongo_database.mongodb.name
      }
      env {
        name  = "SPRING_DATA_MONGODB_USERNAME"
        value = azurerm_cosmosdb_mongo_database.mongodb.connection.user
      }
      env {
        name  = "SPRING_DATA_MONGODB_PASSWORD"
        value = azurerm_cosmosdb_mongo_database.mongodb.connection.password
      }
      */
      env {
        name  = "SPRING_DATA_MONGODB_AUTOINDEXCREATION"
        value = "true"
      }
    }
  }
  depends_on = [
    azurerm_cosmosdb_account.db
  ]
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "tfex-cosmos-db-${azurerm_resource_group.res-0.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.res-0.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_free_tier = true
  enable_automatic_failover = true

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
}

resource "azurerm_cosmosdb_mongo_database" "mongodb" {
  name                = "ldes"
  resource_group_name = azurerm_cosmosdb_account.db.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
  throughput          = 400
}