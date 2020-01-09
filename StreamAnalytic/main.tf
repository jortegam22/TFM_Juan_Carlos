//ASA Configuration

resource "azurerm_stream_analytics_job" "asajob" {
  name                                     = "_asa_name_"
  resource_group_name                      = "_resource_group_name_"
  location                                 = "_resource_group_location_"
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
    FROM eventhub
  )

    SELECT *
    INTO blobstorage2
    FROM Eventos

    SELECT *
    INTO blobstorage
    FROM Eventos
    WHERE 1=1 and environment = _entorno_ and eventType = 'Error'
  QUERY
}

resource "azurerm_eventhub_consumer_group" "cg" {
  name                = "_consumergroup_name_"
  namespace_name      = "_eventhub_namespace_name_"
  eventhub_name       = "_eventhub_eventhub_name_"
  resource_group_name = "_resource_group_name_"
}

resource "azurerm_stream_analytics_stream_input_eventhub" "asajobevent" {
  name                         = "eventhub"
  stream_analytics_job_name    = azurerm_stream_analytics_job.asajob.name
  resource_group_name          = "_resource_group_name_"
  eventhub_consumer_group_name = azurerm_eventhub_consumer_group.cg.name
  eventhub_name                = "_eventhub_eventhub_name_"
  servicebus_namespace         = "_eventhub_namespace_name_"
  shared_access_policy_key     = "_eventhub_namespace_access_policy_key_"
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "storejob" {
  name                      = "blobstorage"
  stream_analytics_job_name = azurerm_stream_analytics_job.asajob.name
  resource_group_name       = "_resource_group_name_"
  storage_account_name      = "_storage_account_name_"
  storage_account_key       = "_storage_account_key_"
  storage_container_name    = "_storage_container_name_"
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}

resource "azurerm_stream_analytics_output_blob" "processjob" {
  name                      = "blobstorage2"
  stream_analytics_job_name = azurerm_stream_analytics_job.asajob.name
    resource_group_name     = "_resource_group_name_"
  storage_account_name      = "_storage_account_name_"
  storage_account_key       = "_storage_account_key_"
  storage_container_name    = "_storage_container2_name_"
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}