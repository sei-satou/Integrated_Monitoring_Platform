locals {
  windows_web_rg = "${var.windows_web_prefix}-rg"

  # シンセティックの実行場所(API の名前)と、IP 範囲リスト内の対応するキー
  synthetics_location     = "AP_NORTHEAST_1"
  synthetics_location_key = "Tokyo, JP"

  synthetics_source_cidrs = jsondecode(data.http.synthetics_ip_ranges.response_body)[local.synthetics_location_key]
}

# windows_web で作成済みのリソースを参照する
data "azurerm_virtual_machine" "windows_web" {
  name                = "${var.windows_web_prefix}-vm"
  resource_group_name = local.windows_web_rg
}

data "azurerm_public_ip" "windows_web" {
  name                = "${var.windows_web_prefix}-pip"
  resource_group_name = local.windows_web_rg
}

# New Relic が公開している監視元 IP 範囲のリスト(US / EU / JP アカウント共通)
data "http" "synthetics_ip_ranges" {
  url = "https://s3.amazonaws.com/nr-synthetics-assets/nat-ip-dnsname/production/ip-ranges.json"
}

# --- Infrastructure エージェント -------------------------------------------------
# windows_web が CustomScript 拡張を使用済みで 2 つ目は追加できないため Run Command で導入する
resource "azurerm_virtual_machine_run_command" "newrelic_infra" {
  name               = "install-newrelic-infra"
  location           = data.azurerm_virtual_machine.windows_web.location
  virtual_machine_id = data.azurerm_virtual_machine.windows_web.id

  source {
    script = file("${path.module}/scripts/install_newrelic_infra.ps1")
  }

  protected_parameter {
    name  = "LicenseKey"
    value = var.newrelic_license_key
  }

  # azurerm の Run Command はスクリプトが失敗しても成功扱いになるため、終了コードを検査する
  lifecycle {
    postcondition {
      condition     = self.instance_view[0].exit_code == 0
      error_message = "New Relic Infrastructure エージェントの導入に失敗しました。README のトラブルシューティングを確認してください。"
    }
  }
}

# --- シンセティックモニター ------------------------------------------------------
# windows_web の HTTP は allowed_cidrs に限定されているため、監視元の IP 範囲を追加で許可する
resource "azurerm_network_security_rule" "allow_synthetics" {
  name                        = "allow-newrelic-synthetics"
  resource_group_name         = local.windows_web_rg
  network_security_group_name = "${var.windows_web_prefix}-nsg"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefixes     = local.synthetics_source_cidrs
  destination_address_prefix  = "*"
}

resource "newrelic_synthetics_monitor" "windows_web_http" {
  name             = "${var.windows_web_prefix}-http"
  type             = "SIMPLE"
  status           = "ENABLED"
  period           = var.synthetics_period
  uri              = "http://${data.azurerm_public_ip.windows_web.ip_address}/"
  locations_public = [local.synthetics_location]

  depends_on = [azurerm_network_security_rule.allow_synthetics]
}
