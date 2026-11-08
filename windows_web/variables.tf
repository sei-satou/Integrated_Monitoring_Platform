variable "subscription_id" {
  description = "デプロイ先の Azure サブスクリプション ID"
  type        = string
}

variable "allowed_cidrs" {
  description = "RDP(3389) と Web(80) への接続を許可する送信元 CIDR のリスト"
  type        = list(string)

  validation {
    condition = length(var.allowed_cidrs) > 0 && alltrue([
      for cidr in var.allowed_cidrs : can(cidrhost(cidr, 0)) && cidr != "0.0.0.0/0"
    ])
    error_message = "allowed_cidrs には 0.0.0.0/0 以外の CIDR を 1 つ以上指定してください。"
  }
}

variable "zabbix_server_prefix" {
  description = "Zabbix サーバ構築時に指定した prefix。既存の VNet と NIC の検索に使う"
  type        = string
  default     = "zabbix-test"
}

variable "prefix" {
  description = "リソース名の接頭辞"
  type        = string
  default     = "windows-web"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,40}$", var.prefix))
    error_message = "prefix は英小文字・数字・ハイフンのみ、40 文字以内で指定してください。"
  }
}

variable "computer_name" {
  description = "Windows のコンピューター名。Zabbix のホスト名としても使う"
  type        = string
  default     = "win-web01"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,15}$", var.computer_name))
    error_message = "computer_name は英数字とハイフンのみ、15 文字以内で指定してください。"
  }
}

variable "vm_size" {
  description = "VM サイズ"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "VM の管理ユーザー名"
  type        = string
  default     = "azureadmin"
}

variable "os_disk_storage_account_type" {
  description = "OS ディスクのストレージ種別"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "subnet_address_prefix" {
  description = "Zabbix サーバの VNet に追加するサブネットのアドレス範囲"
  type        = string
  default     = "10.10.2.0/24"
}

variable "timezone" {
  description = "Windows のタイムゾーン"
  type        = string
  default     = "Tokyo Standard Time"
}

variable "zabbix_agent_version" {
  description = "インストールする Zabbix エージェントのバージョン"
  type        = string
  default     = "8.0.0"

  validation {
    condition     = can(regex("^8\\.0\\.[0-9]+$", var.zabbix_agent_version))
    error_message = "zabbix_agent_version は 8.0.x の形式で指定してください。"
  }
}

variable "tags" {
  description = "全リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
