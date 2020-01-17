//Resource Group Configuration

resource "azurerm_resource_group" "rg" {
  name     = "_rg_name_"
  location = "_rg_location_"
}

//IoTHub Configuration

resource "azurerm_iothub" "iothub" {
  name                = "_iothub_name_"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  sku {
    name     = "F1"
    tier     = "Standard"
    capacity = "1"
  }

endpoint {
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.sa.primary_blob_connection_string
    name                       = "_endpoint_name_"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    container_name             = azurerm_storage_container.pre_asa.name 
    encoding                   = "Json"
    file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  }

  route {
    name           = "_endpoint_name_"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["_endpoint_name_"]
    enabled        = true
  }
}

//Storage Account and Containers Configuration

resource "azurerm_storage_account" "sa" {
  name                     = "_sa_name_"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "pre_asa" {
  name                  = "_pre_ASA_"
  resource_group_name   = azurerm_resource_group.rg.name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "container"
}

resource "azurerm_storage_container" "post_asa" {
  name                  = "_post_ASA_"
  resource_group_name   = azurerm_resource_group.rg.name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "container"
}

//Stream Analytic Configuration

resource "azurerm_stream_analytics_job" "asa" {
  name                                     = "_asa_name_"
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
    FROM _asa_input_name_
  )

    SELECT *
    INTO _asa_output_blob_name_
    FROM Eventos
    WHERE eventType = 'Error'
  QUERY
}

resource "azurerm_stream_analytics_stream_input_iothub" "example" {
  name                         = "_asa_input_name_"
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
  name                      = "_asa_output_name_"
  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  resource_group_name       = azurerm_resource_group.rg.name
  storage_account_name      = azurerm_storage_account.sa.name
  storage_account_key       = azurerm_storage_account.sa.primary_access_key
  storage_container_name    = azurerm_storage_container.post_asa.name
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}