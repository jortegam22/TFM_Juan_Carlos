//ASA Configuration

resource "azurerm_stream_analytics_job" "asajob" {
  name                                     = var.asa_name
  resource_group_name                      = var.group_name
  location                                 = var.group_location
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
    WHERE 1=1 and eventType = 'Error'
  QUERY
}

resource "azurerm_eventhub_consumer_group" "cg" {
  name                = var.consumergroup_name
  namespace_name      = var.namespace_name
  eventhub_name       = var.eventhub_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_stream_analytics_stream_input_eventhub" "asajobevent" {
  name                         = "eventhub"
  stream_analytics_job_name    = azurerm_stream_analytics_job.asajob.name
  resource_group_name          = var.group_name
  eventhub_consumer_group_name = azurerm_eventhub_consumer_group.cg.name
  eventhub_name                = var.eventhub_name
  servicebus_namespace         = var.namespace_name
  shared_access_policy_key     = var.namespace_access_policy_key
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "storejob" {
  name                      = "blobstorage"
  stream_analytics_job_name = azurerm_stream_analytics_job.asajob.name
  resource_group_name       = var.group_name
  storage_account_name      = var.storage_account_name
  storage_account_key       = var.storage_account_key
  storage_container_name    = var.storage_container_name
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
    resource_group_name     = var.group_name
  storage_account_name      = var.storage_account_name
  storage_account_key       = var.storage_account_key
  storage_container_name    = var.storage_container_name
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}