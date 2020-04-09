//Terraform Configuration

provider "azurerm" {
  version = "=2.0.0"
  features {}
}

//Resource Group Information

data "azurerm_resource_group" "rg" {
  name = "__rg_name__"
}

//ASA Configuration

resource "azurerm_stream_analytics_job" "asa" {
  name                                     = "__asa_name__"
  resource_group_name                      = azurerm_resource_group.rg.name
  location                                 = "__rg_location__"
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
    FROM __asa_input_name__
  )

  SELECT *
  INTO __asa_output_name__
  FROM Eventos
  WHERE eventType = 'Error' and This is a test :)
  QUERY
}

//EventHubNameSpace Information

data "azurerm_eventhub_namespace" "ehns" {
  name = "__ehns_name__"
}

//EventHub Information

data "azurerm_eventhub" "eh" {
  name = "__eh_name__"
}

resource "azurerm_stream_analytics_stream_input_eventhub" "asainput" {
  name                         = "__asa_input_name__"
  stream_analytics_job_name    = azurerm_stream_analytics_job.asa.name
  resource_group_name          = azurerm_resource_group.rg.name
  eventhub_consumer_group_name = "__ehcg_name__"
  eventhub_name                = azurerm_eventhub.eh.name
  servicebus_namespace         = azurerm_eventhub_namespace.ehns.name
  shared_access_policy_key     = "__ehns_access_policy_key__"
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

//StorageAccount Information

data "azurerm_storage_account" "sa" {
  name = "__sa_name__"
}

//Container Information

data "azurerm_storage_container" "sc" {
  name = "__post_ASA__"
}

resource "azurerm_stream_analytics_output_blob" "asablob" {
  name                      = "__asa_output_name__"
  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  resource_group_name       = azurerm_resource_group.rg.name
  storage_account_name      = azurerm_storage_account.sa.name
  storage_account_key       = "__sa_key__"
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
