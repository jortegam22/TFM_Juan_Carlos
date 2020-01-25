//Resource Group Configuration

resource "azurerm_resource_group" "rg" {
  name     = "__rg_name__"
  location = "__rg_location__"
}

//IoTHub Configuration

resource "azurerm_iothub" "iothub" {
  name                = "__iothub_name__"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  sku {
    name     = "__iot_sku_name__"
    tier     = "__iot_sku_tier__"
    capacity = "1"
  }

endpoint {
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.sa.primary_blob_connection_string
    name                       = "__endpoint_name__"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    container_name             = "__pre_ASA__"
    encoding                   = "Json"
    file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  }

  route {
    name           = "__endpoint_name__"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["__endpoint_name__"]
    enabled        = true
  }
}

//Storage Account and Containers Configuration

resource "azurerm_storage_account" "sa" {
  name                     = "__storage_name__"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

/*resource "azurerm_storage_container" "pre_asa" {
  name                  = "__pre_ASA__"
  resource_group_name   = azurerm_resource_group.rg.name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "container"
}

resource "azurerm_storage_container" "post_asa" {
  name                  = "__post_ASA__"
  resource_group_name   = azurerm_resource_group.rg.name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "container"
}*/

//Stream Analytic Configuration

resource "azurerm_stream_analytics_job" "asa" {
  name                                     = "__asa_name__"
  resource_group_name                      = azurerm_resource_group.rg.name
  location                                 = azurerm_resource_group.rg.location
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
    WHERE eventType = 'Error'
  QUERY
}

resource "azurerm_stream_analytics_stream_input_iothub" "example" {
  name                         = "__asa_input_name__"
  stream_analytics_job_name    = azurerm_stream_analytics_job.asa.name
  resource_group_name          = azurerm_stream_analytics_job.asa.resource_group_name
  endpoint                     = "messages/events"
  eventhub_consumer_group_name = "$Default"
  iothub_namespace             = azurerm_iothub.iothub.name
  shared_access_policy_key     = azurerm_iothub.iothub.shared_access_policy.0.primary_key
  shared_access_policy_name    = "iothubowner"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "prodbs" {
  name                      = "__asa_output_name__"
  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  resource_group_name       = azurerm_resource_group.rg.name
  storage_account_name      = azurerm_storage_account.sa.name
  storage_account_key       = azurerm_storage_account.sa.primary_access_key
  storage_container_name    = "__post_ASA__"
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}