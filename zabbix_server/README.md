# zabbix_server

Azure 上に Zabbix 8.0 サーバを構築する Terraform コードです。
RHEL 10 の VM を 1 台作成し、初回起動時のスクリプトで Apache + PHP-FPM + PostgreSQL + Zabbix を自動でセットアップします。

> [!NOTE]
> `terraform validate` とモックによる `terraform test` は確認済みですが、Azure への実デプロイと RHEL 10 上でのスクリプト実行は未検証です。

## 作成されるもの

- リソースグループ、仮想ネットワーク、サブネット
- NSG（SSH と HTTP は `allowed_cidrs` からのみ許可）
- 静的パブリック IP
- RHEL 10 VM（既定は `Standard_D2s_v5`）
- PostgreSQL 用データディスク（既定は 128 GiB、`/var/lib/pgsql` にマウント）

## 前提条件

- Terraform 1.9 以上
- Azure CLI（`az login` 済みであること）
- SSH 鍵ペア

## 使い方

1. 設定ファイルを作成し、値を編集します。

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   | 変数 | 内容 |
   |---|---|
   | `subscription_id` | デプロイ先のサブスクリプション ID |
   | `ssh_public_key_path` | SSH 公開鍵のパス |
   | `allowed_cidrs` | SSH と Web の接続を許可する CIDR（`0.0.0.0/0` は指定不可） |

   その他の変数は [variables.tf](variables.tf) を参照してください。

2. デプロイします。

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. VM に SSH 接続し、セットアップの完了を待ちます。`status: done` と表示されれば成功です。

   ```bash
   ssh -i <秘密鍵のパス> azureuser@<public_ip_address>
   sudo cloud-init status --wait
   ```

   失敗した場合は `/var/log/cloud-init-output.log` を確認してください。

4. `terraform output zabbix_url` の URL をブラウザで開き、`Admin` / `zabbix` でログインします。**初期パスワードはすぐに変更してください。**

## 削除

```bash
terraform destroy
```

## 注意事項

- 通信は HTTP のみです。TLS は設定していません。
- RHEL の従量課金イメージを使うため、VM 料金に RHEL のライセンス料が加算されます。
- 起動スクリプトは初回起動時のみ実行されます。[templates/bootstrap.sh.tftpl](templates/bootstrap.sh.tftpl) を変更して `terraform apply` しても、既存の VM には反映されません。
