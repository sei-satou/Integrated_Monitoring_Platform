output "public_ip_address" {
  description = "Web サーバのパブリック IP アドレス(RDP 接続先)"
  value       = azurerm_public_ip.this.ip_address
}

output "web_url" {
  description = "IIS の URL"
  value       = "http://${azurerm_public_ip.this.ip_address}/"
}

output "admin_username" {
  description = "VM の管理ユーザー名"
  value       = var.admin_username
}

output "admin_password" {
  description = "VM の管理ユーザーのパスワード"
  value       = random_password.admin.result
  sensitive   = true
}

output "zabbix_host_name" {
  description = "Zabbix にホスト登録するときのホスト名"
  value       = var.computer_name
}

output "zabbix_agent_interface_ip" {
  description = "Zabbix にホスト登録するときのエージェントインターフェース IP"
  value       = azurerm_network_interface.this.private_ip_address
}
