output "public_ip_address" {
  description = "Zabbix サーバのパブリック IP アドレス"
  value       = azurerm_public_ip.this.ip_address
}

output "zabbix_url" {
  description = "Zabbix フロントエンドの URL"
  value       = "http://${azurerm_public_ip.this.ip_address}/zabbix/"
}

output "ssh_command" {
  description = "VM への SSH 接続コマンド"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}"
}
