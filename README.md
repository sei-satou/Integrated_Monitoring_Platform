# zabbix_test

Azure 上に Zabbix の検証環境を構築する Terraform コードです。

| ディレクトリ | 内容 |
|---|---|
| [zabbix_server](zabbix_server/) | Zabbix サーバ 8.0（RHEL 10 / Apache / PHP / PostgreSQL） |
| [windows_web](windows_web/) | 監視対象の Web サーバ（Windows Server 2022 / IIS / SQL Server / Zabbix エージェント） |

`windows_web` は `zabbix_server` の VNet を利用します。各ディレクトリの README に沿って、次の順番で実行してください。

- 構築: `zabbix_server` → `windows_web`
- 削除: `windows_web` → `zabbix_server`
