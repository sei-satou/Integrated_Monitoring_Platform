output "synthetics_monitor_name" {
  description = "シンセティックモニターの名前"
  value       = newrelic_synthetics_monitor.windows_web_http.name
}

output "monitored_url" {
  description = "シンセティックモニターの監視先 URL"
  value       = newrelic_synthetics_monitor.windows_web_http.uri
}
