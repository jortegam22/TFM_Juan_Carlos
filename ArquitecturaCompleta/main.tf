//Terraform Configuration

provider "azurerm" {
  version = "=2.0.0"
  features {}
}

//Resource Group Configuration

resource "azurerm_resource_group" "rg" {
  name     = "__rg_name__"
  location = "__rg_location__"
}

//EventHub Configuration

resource "azurerm_eventhub_namespace" "ehns" {
  name                = "__ns_name__"
  location            = "__rg_location__"
  resource_group_name = "__rg_name__"
  sku                 = "Basic"
}

resource "azurerm_eventhub" "eh" {
  name                = "__eh_name__"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = "__rg_name__"
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "ar" {
  name                = "__ar_name__"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  eventhub_name       = azurerm_eventhub.eh.name
  resource_group_name = "__rg_name__"

  listen = false
  send   = true
  manage = false
}

//IoTHub Configuration

resource "azurerm_iothub" "iothub" {
  name                = "__iothub_name__"
  resource_group_name = "__rg_name__"
  location            = "__rg_location__"
  
  sku {
    name     = "__iot_sku_name__"
    capacity = "1"
  }

  route {
    name           = "__endpoint_name__"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["__endpoint_name__"]
    enabled        = true
  }
}

resource "azurerm_iothub_endpoint_eventhub" "iotep" {
  resource_group_name = "__rg_name__"
  iothub_name         = azurerm_iothub.iothub.name
  name                = "__epeh_name__"

  connection_string = azurerm_eventhub_authorization_rule.ar.primary_connection_string
}

resource "azurerm_iothub_route" "iotroute" {
  resource_group_name = "__rg_name__"
  iothub_name         = azurerm_iothub.iothub.name
  name                = "__endpoint_name__"

  source         = "DeviceMessages"
  condition      = "true"
  endpoint_names = ["__pre_ASA__"]
  enabled        = true
}

//Storage Account Configuration

resource "azurerm_storage_account" "sa" {
  name                     = "__storage_name__"
  resource_group_name      = "__rg_name__"
  location                 = "__rg_location__"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

//Stream Analytic Configuration

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
  WHERE eventType = 'Error'
  QUERY
}

resource "azurerm_eventhub_consumer_group" "ehcg" {
  name                = "__ehcg_name__"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  eventhub_name       = azurerm_eventhub.eh.name
  resource_group_name = "__rg_name__"
}

resource "azurerm_stream_analytics_stream_input_eventhub" "sainput" {
  name                         = "__asa_input_name__"
  stream_analytics_job_name    = azurerm_stream_analytics_job.asa.name
  resource_group_name          = "__rg_name__"
  eventhub_consumer_group_name = azurerm_eventhub_consumer_group.ehcg.name
  eventhub_name                = azurerm_eventhub.eh.name
  servicebus_namespace         = azurerm_eventhub_namespace.ehns.name
  shared_access_policy_key     = azurerm_eventhub_namespace.ehns.default_primary_key
  shared_access_policy_name    = "iothubowner"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "prodbs" {
  name                      = "__asa_output_name__"
  stream_analytics_job_name = azurerm_stream_analytics_job.asa.name
  resource_group_name       = "__rg_name__"
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
