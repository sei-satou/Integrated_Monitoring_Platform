# newrelic_monitoring

[windows_web](../windows_web/) の Windows VM を New Relic で監視する Terraform コードです。

> [!NOTE]
> `terraform validate` とモックによる `terraform test` は確認済みですが、Azure / New Relic への実デプロイは未検証です。

## 構成

| 項目 | 内容 |
|---|---|
| Infrastructure エージェント | Azure Run Command で VM に導入し、CPU・メモリ・ディスクなどを収集 |
| シンセティックモニター | `http://<VM のパブリック IP>/` を東京から 5 分間隔で HTTP チェック（`SIMPLE` タイプ） |
| NSG ルール | New Relic の東京の監視元 IP 範囲から HTTP(80) を許可 |

アラートポリシーは含みません。

## 前提条件

- [windows_web](../windows_web/) をデプロイ済みであること
- Terraform 1.9 以上
- Azure CLI（`az login` 済みであること）
- New Relic のアカウント ID、ユーザーキー（`NRAK` で始まるキー）、ライセンスキー

## 使い方

1. 設定ファイルを作成し、値を編集します。

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. デプロイします。

   ```bash
   terraform init
   terraform apply
   ```

3. New Relic の画面で確認します。

   - **Infrastructure > Hosts** に `win-web01` が表示されること
   - **Synthetic Monitoring** に `windows-web-http` が表示され、成功していること

## 削除

`windows_web` より先に削除してください。エージェントは VM 内に残りますが、VM を削除すれば一緒になくなります。

```bash
terraform destroy
```

## トラブルシューティング

エージェントの導入に失敗した場合は、次のコマンドで実行結果を確認してください。

```bash
az vm run-command show --name install-newrelic-infra --vm-name windows-web-vm \
  --resource-group windows-web-rg --expand instanceView
```

## 注意事項

- `terraform.tfvars` と `terraform.tfstate` には API キーやライセンスキーが含まれます。共有しないでください。
- New Relic の監視元 IP 範囲が変わった場合は、`terraform apply` を再実行すると NSG ルールに反映されます。
- シンセティックモニターの実行回数は、New Relic のプランによっては課金対象になります。
