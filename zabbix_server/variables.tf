variable "subscription_id" {
  description = "デプロイ先の Azure サブスクリプション ID"
  type        = string
}

variable "ssh_public_key_path" {
  description = "VM の管理ユーザーに登録する SSH 公開鍵ファイルのパス"
  type        = string
}

variable "allowed_cidrs" {
  description = "SSH(22) と Web(80) への接続を許可する送信元 CIDR のリスト"
  type        = list(string)

  validation {
    condition = length(var.allowed_cidrs) > 0 && alltrue([
      for cidr in var.allowed_cidrs : can(cidrhost(cidr, 0)) && cidr != "0.0.0.0/0"
    ])
    error_message = "allowed_cidrs には 0.0.0.0/0 以外の CIDR を 1 つ以上指定してください。"
  }
}

variable "agent_cidrs" {
  description = "Zabbix トラッパー(10051)への接続を許可する送信元 CIDR のリスト。アクティブエージェントを使う場合に指定する"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.agent_cidrs : can(cidrhost(cidr, 0)) && cidr != "0.0.0.0/0"])
    error_message = "agent_cidrs には 0.0.0.0/0 以外の CIDR を指定してください。"
  }
}

variable "location" {
  description = "Azure リージョン"
  type        = string
  default     = "japaneast"
}

variable "prefix" {
  description = "リソース名の接頭辞"
  type        = string
  default     = "zabbix-test"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,40}$", var.prefix))
    error_message = "prefix は英小文字・数字・ハイフンのみ、40 文字以内で指定してください。"
  }
}

variable "vm_size" {
  description = "VM サイズ。既定値は Zabbix の小規模構成の要件(2 vCPU / 8 GiB)に合わせている"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "VM の管理ユーザー名"
  type        = string
  default     = "azureuser"
}

variable "disk_storage_account_type" {
  description = "OS ディスクとデータディスクのストレージ種別"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "data_disk_size_gb" {
  description = "PostgreSQL 用データディスクのサイズ(GiB)"
  type        = number
  default     = 128
}

variable "vnet_address_space" {
  description = "仮想ネットワークのアドレス空間"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_address_prefix" {
  description = "サブネットのアドレス範囲"
  type        = string
  default     = "10.10.1.0/24"
}

variable "timezone" {
  description = "OS と PHP に設定するタイムゾーン"
  type        = string
  default     = "Asia/Tokyo"

  validation {
    condition     = can(regex("^[A-Za-z0-9_+/-]+$", var.timezone))
    error_message = "timezone は Asia/Tokyo のような形式で指定してください。"
  }
}

variable "tags" {
  description = "全リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
