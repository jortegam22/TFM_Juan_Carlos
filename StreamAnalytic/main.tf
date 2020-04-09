//Terraform Configuration

provider "azurerm" {
  version = "=2.0.0"
  features {}
}

//ASA Configuration

resource "azurerm_stream_analytics_job" "asa" {
  name                                     = asa_name.default
  resource_group_name                      = rg_name.default
  location                                 = rg_location.default
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
    FROM EventHub
  )

  SELECT *
  INTO Blob
  FROM Eventos
  WHERE eventType = 'Error'
  QUERY
}

resource "azurerm_stream_analytics_stream_input_eventhub" "asainput" {
  name                         = var.asa_input_name
  stream_analytics_job_name    = azurerm_stream_analytics_job.asa.name
  resource_group_name          = var.rg_name
  eventhub_consumer_group_name = var.ehcg_name
  eventhub_name                = var.eh_name
  servicebus_namespace         = var.ehns_name
  shared_access_policy_key     = var.ehns_access_policy_key
  shared_access_policy_name    = "RootManageSharedAccessKey"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "asablob" {
  name                      = var.asa_output_name
  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  resource_group_name       = var.rg_name
  storage_account_name      = var.sa_name
  storage_account_key       = var.sa_key
  storage_container_name    = var.post_ASA
  path_pattern              = "datos"
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Json"
    encoding        = "UTF8"
    format          = "LineSeparated"
  }
}
