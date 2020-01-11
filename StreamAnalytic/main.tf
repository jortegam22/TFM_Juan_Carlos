//ASA Configuration

resource "azurerm_stream_analytics_job" "asajob" {
  name                                     = "__asa_name__"
  resource_group_name                      = "__resource_group_name__"
  location                                 = "__resource_group_location__"
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
    WHERE 1=1 and  environment = __entorno__  and eventType = 'Error'
  QUERY
}

resource "azurerm_eventhub_consumer_group" "cg" {
  name                = "__consumergroup_name__"
  namespace_name      = "__eventhub_namespace_name__"
  eventhub_name       = "__eventhub_eventhub_name__"
  resource_group_name = "__resource_group_name__"
}

resource "azurerm_stream_analytics_stream_input_eventhub" "asajobevent" {
  name                         = "eventhub"
  stream_analytics_job_name    = azurerm_stream_analytics_job.asajob.name
  resource_group_name          = "__resource_group_name__"
  eventhub_consumer_group_name = azurerm_eventhub_consumer_group.cg.name
  eventhub_name                = "__eventhub_eventhub_name__"
  servicebus_namespace         = "__eventhub_namespace_name__"
  shared_access_policy_key     = "__eventhub_namespace_access_policy_key__"
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "storejob" {
  name                      = "blobstorage"
  stream_analytics_job_name = azurerm_stream_analytics_job.asajob.name
  resource_group_name       = "__resource_group_name__"
  storage_account_name      = "__storage_account_name__"
  storage_account_key       = "__storage_account_key__"
  storage_container_name    = "__storage_container_name__"
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
    resource_group_name     = "__resource_group_name__"
  storage_account_name      = "__storage_account_name__"
  storage_account_key       = "__storage_account_key__"
  storage_container_name    = "__storage_container2_name__"
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}