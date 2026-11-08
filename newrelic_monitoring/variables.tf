variable "subscription_id" {
  description = "windows_web をデプロイした Azure サブスクリプション ID"
  type        = string
}

variable "newrelic_account_id" {
  description = "New Relic のアカウント ID"
  type        = number
}

variable "newrelic_api_key" {
  description = "New Relic のユーザーキー(NRAK で始まるキー)。シンセティックモニターの作成に使う"
  type        = string
  sensitive   = true
}

variable "newrelic_license_key" {
  description = "New Relic のライセンスキー(インジェストキー)。Infrastructure エージェントが使う"
  type        = string
  sensitive   = true
}

variable "newrelic_region" {
  description = "New Relic アカウントのデータセンターリージョン"
  type        = string
  default     = "US"

  validation {
    condition     = contains(["US", "EU", "JP"], var.newrelic_region)
    error_message = "newrelic_region は US、EU、JP のいずれかを指定してください。"
  }
}

variable "windows_web_prefix" {
  description = "windows_web 構築時に指定した prefix。既存の VM などの検索に使う"
  type        = string
  default     = "windows-web"
}

variable "synthetics_period" {
  description = "シンセティックモニターの実行間隔"
  type        = string
  default     = "EVERY_5_MINUTES"
}
