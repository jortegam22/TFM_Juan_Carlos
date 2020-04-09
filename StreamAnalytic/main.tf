//Terraform Configuration

provider "azurerm" {
  version = "=2.0.0"
  features {}
}

//Resource Group Information

data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

//ASA Configuration

resource "azurerm_stream_analytics_job" "asa" {
  name                                     = var.asa_name
  resource_group_name                      = azurerm_resource_group.rg.name
  location                                 = var.rg_location
  compatibility_level                      = "1.1"
  data_locale                              = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 3

  transformation_query = <<QUERY
  WITH Eventos AS (
    SELECT *
    FROM var.asa_input_name
  )

  SELECT *
  INTO var.asa_output_name
  FROM Eventos
  WHERE eventType = 'Error' and This is a test :)
  QUERY
}

//EventHubNameSpace Information

data "azurerm_eventhub_namespace" "ehns" {
  name = var.ehns_name
}

//EventHub Information

data "azurerm_eventhub" "eh" {
  name = var.eh_name
}

resource "azurerm_stream_analytics_stream_input_eventhub" "asainput" {
  name                         = var.asa_input_name
  stream_analytics_job_name    = azurerm_stream_analytics_job.asa.name
  resource_group_name          = azurerm_resource_group.rg.name
  eventhub_consumer_group_name = var.ehcg_name
  eventhub_name                = azurerm_eventhub.eh.name
  servicebus_namespace         = azurerm_eventhub_namespace.ehns.name
  shared_access_policy_key     = var.ehns_access_policy_key
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

//StorageAccount Information

data "azurerm_storage_account" "sa" {
  name = var.sa_name
}

//Container Information

data "azurerm_storage_container" "sc" {
  name = var.post_ASA
}

resource "azurerm_stream_analytics_output_blob" "asablob" {
  name                      = var.asa_output_name
  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  resource_group_name       = azurerm_resource_group.rg.name
  storage_account_name      = azurerm_storage_account.sa.name
  storage_account_key       = var.sa_key
  storage_container_name    = azurerm_storage_container.name
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}
