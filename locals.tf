locals {
  # General
  location_short  = var.environment.location == "italynorth" ? "itn" : var.environment.location == "westeurope" ? "weu" : var.environment.location == "germanywestcentral" ? "gwc" : "neu"
  project         = "${var.environment.prefix}-${var.environment.env_short}-${local.location_short}"
  domain          = var.environment.domain == null ? "-" : "-${var.environment.domain}-"
  app_name_prefix = "${local.project}${local.domain}${var.environment.app_name}"

  eventhub = {
    name = "${local.app_name_prefix}-evhns-${var.environment.instance_number}"
    sku_name = lookup(
      {
        "s" = "Standard",
        "m" = "Standard",
        "l" = "Premium"
      },
      var.tier,
      "Premium" # Default
    )
    # Note: Basic SKU does not support private access
  }

  # Events configuration
  consumers = { for hc in flatten([for h in var.eventhubs :
    [for c in h.consumers : {
      hub  = "${local.app_name_prefix}-${h.name}-${var.environment.instance_number}"
      name = c
  }]]) : "${hc.hub}.${hc.name}" => hc }

  keys = { for hk in flatten([for h in var.eventhubs :
    [for k in h.keys : {
      hub = "${local.app_name_prefix}-${h.name}-${var.environment.instance_number}"
      key = k
  }]]) : "${hk.hub}.${hk.key.name}" => hk }

  hubs = { for h in var.eventhubs : "${local.app_name_prefix}-${h.name}-${var.environment.instance_number}" => h }

  # Network
  private_dns_zone_resource_group_name = var.private_dns_zone_resource_group_name == null ? var.resource_group_name : var.private_dns_zone_resource_group_name

  # Autoscaling
  auto_inflate_enabled     = var.tier == "l" ? true : false
  maximum_throughput_units = local.auto_inflate_enabled ? 15 : null
  capacity                 = var.tier == "m" ? 1 : var.tier == "l" ? 2 : null
}
