# windows_web

Zabbix の監視対象となる Windows の Web サーバを Azure 上に構築する Terraform コードです。

> [!NOTE]
> `terraform validate` とモックによる `terraform test` は確認済みですが、Azure への実デプロイと起動スクリプトの実行は未検証です。

## 構成

| 項目 | 内容 |
|---|---|
| OS | Windows Server 2022 |
| Web | IIS |
| DB | SQL Server 2022 Developer（マーケットプレイスイメージにプリインストール） |
| 監視 | Zabbix エージェント 8.0 |
| ネットワーク | Zabbix サーバの VNet に専用サブネットを追加（既定は `10.10.2.0/24`） |

RDP と HTTP は `allowed_cidrs` からのみ許可します。Zabbix の通信は VNet 内のプライベート IP で行います。SQL Server への外部接続は開けていません。[newrelic_monitoring](../newrelic_monitoring/) をデプロイすると、New Relic の監視元からの HTTP も許可されます。

## 前提条件

- [zabbix_server](../zabbix_server/) をデプロイ済みであること（VNet と NIC を参照します）
- Terraform 1.9 以上
- Azure CLI（`az login` 済みであること）

## 使い方

1. 設定ファイルを作成し、`subscription_id` と `allowed_cidrs` を編集します。

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. デプロイします。IIS と Zabbix エージェントのセットアップまで `terraform apply` の中で実行されます。

   ```bash
   terraform init
   terraform apply
   ```

3. Zabbix のフロントエンドで「データ収集 > ホスト」からホストを作成します。

   | 項目 | 設定値 |
   |---|---|
   | ホスト名 | `terraform output zabbix_host_name` の値 |
   | インターフェース | エージェント、`terraform output zabbix_agent_interface_ip` の値、ポート 10050 |
   | テンプレート | `Windows by Zabbix agent` |

4. RDP で接続する場合のパスワードは次のコマンドで確認します。

   ```bash
   terraform output -raw admin_password
   ```

## 削除

Zabbix サーバより先に削除してください。サブネットが Zabbix サーバの VNet 内にあるためです。

```bash
terraform destroy
```

## 注意事項

- 管理者パスワードは Terraform の state に平文で保存されます。`terraform.tfstate` は共有しないでください。
- SQL Server Developer エディションは開発・テスト専用です。本番では SQL Server のライセンスが必要なエディションに変更してください。
- SKU が利用できない場合は次のコマンドで確認してください。

  ```bash
  az vm image list-skus -l japaneast --publisher MicrosoftSQLServer --offer sql2022-ws2022 -o table
  ```
