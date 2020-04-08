//ASA Configuration

resource "azurerm_stream_analytics_job" "asa" {
  name                                     = "__asa_name__"
  resource_group_name                      = "__rg_name__"
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
    WHERE eventType = 'Error' and This is a test
  QUERY
}

resource "azurerm_stream_analytics_stream_input_eventhub" "sainput" {
  name                         = "__asa_input_name__"
  stream_analytics_job_name    = azurerm_stream_analytics_job.asa.name
  resource_group_name          = "__rg_name__"
  eventhub_consumer_group_name = "__ehcg_name__"
  eventhub_name                = "__eh_name__"
  servicebus_namespace         = "__ehns_name__"
  shared_access_policy_key     = "__ehns_access_policy_key__"
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "prodbs" {
  name                      = "__asa_output_name__"
  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  resource_group_name       = "__rg_name__"
  storage_account_name      = "__sa_name__"
  storage_account_key       = "__sa_key__"
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
