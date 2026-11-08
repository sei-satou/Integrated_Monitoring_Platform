locals {
  zabbix_server_rg = "${var.zabbix_server_prefix}-rg"
  zabbix_server_ip = data.azurerm_network_interface.zabbix_server.private_ip_address
}

# zabbix_server で作成済みのリソースを参照する
data "azurerm_virtual_network" "zabbix_server" {
  name                = "${var.zabbix_server_prefix}-vnet"
  resource_group_name = local.zabbix_server_rg
}

data "azurerm_network_interface" "zabbix_server" {
  name                = "${var.zabbix_server_prefix}-nic"
  resource_group_name = local.zabbix_server_rg
}

resource "azurerm_resource_group" "this" {
  name     = "${var.prefix}-rg"
  location = data.azurerm_virtual_network.zabbix_server.location
  tags     = var.tags
}

# サブネットは VNet と同じリソースグループに作成する必要がある
resource "azurerm_subnet" "this" {
  name                 = "${var.prefix}-snet"
  resource_group_name  = local.zabbix_server_rg
  virtual_network_name = data.azurerm_virtual_network.zabbix_server.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Zabbix の通信(10050/10051)は NSG 既定の AllowVnetInBound で許可される
resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefixes    = var.allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefixes    = var.allowed_cidrs
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "this" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_windows_virtual_machine" "this" {
  name                  = "${var.prefix}-vm"
  computer_name         = var.computer_name
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.this.id]
  timezone              = var.timezone
  tags                  = var.tags

  # 起動スクリプトの配布に使う。VM 上では C:\AzureData\CustomData.bin に保存される
  custom_data = base64encode(templatefile("${path.module}/templates/bootstrap.ps1.tftpl", {
    computer_name        = var.computer_name
    zabbix_agent_version = var.zabbix_agent_version
    zabbix_server_ip     = local.zabbix_server_ip
  }))

  # SQL Server 2022 Developer エディションがプリインストールされたイメージ
  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "sqldev-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
  }

  # custom_data は初回作成時のみ使われる。スクリプト修正で VM が再作成されないようにする
  lifecycle {
    ignore_changes = [custom_data]
  }

  # VM 起動時点でサブネットの NSG が適用済みであることを保証する
  depends_on = [azurerm_subnet_network_security_group_association.this]
}

# 起動スクリプトを実行する。失敗すると terraform apply もエラーになる
resource "azurerm_virtual_machine_extension" "bootstrap" {
  name                       = "bootstrap"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = jsonencode({
    commandToExecute = "powershell -NoProfile -ExecutionPolicy Bypass -Command \"Copy-Item C:\\AzureData\\CustomData.bin C:\\AzureData\\bootstrap.ps1 -Force; & C:\\AzureData\\bootstrap.ps1\""
  })
}
