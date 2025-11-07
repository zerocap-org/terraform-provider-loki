# Manage multiple Loki rule groups using YAML content
resource "loki_rules" "example" {
  namespace = "my-namespace"

  content = <<EOT
groups:
  - name: example-alerting-group
    interval: 1m
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({app="myapp"} |= "error" [5m])) by (job)
            /
          sum(rate({app="myapp"}[5m])) by (job)
            > 0.05
        for: 10m
        labels:
          severity: warning
          team: backend
        annotations:
          summary: High error rate detected
          description: Error rate is above 5% for {{ $labels.job }}

      - alert: LogVolumeHigh
        expr: |
          sum(rate({namespace="production"}[5m])) > 1000
        for: 5m
        labels:
          severity: info
        annotations:
          summary: High log volume in production

  - name: example-recording-group
    interval: 30s
    rules:
      - record: job:log_lines_total:rate5m
        expr: sum(rate({job=~".+"}[5m])) by (job)
        labels:
          type: counter

      - record: namespace:log_bytes_total:rate1m
        expr: sum(rate({namespace=~".+"}[1m])) by (namespace)
        labels:
          type: gauge
EOT
}

# Manage rules from an external YAML file
resource "loki_rules" "from_file" {
  namespace    = "monitoring"
  content_file = "${path.module}/rules.yaml"
}

# Manage only specific groups from YAML content
resource "loki_rules" "selective" {
  namespace = "prod-alerts"

  content = <<EOT
groups:
  - name: critical-alerts
    rules:
      - alert: ServiceDown
        expr: 'up{job="api-server"} == 0'
        for: 5m
        labels:
          severity: critical

  - name: warning-alerts
    rules:
      - alert: HighLatency
        expr: 'histogram_quantile(0.99, rate({job="api-server"}[5m])) > 1'
        for: 10m
        labels:
          severity: warning

  - name: info-alerts
    rules:
      - alert: NewDeployment
        expr: 'changes(app_version[5m]) > 0'
        labels:
          severity: info
EOT

  # Only manage critical and warning alerts
  only_groups = ["critical-alerts", "warning-alerts"]
}

# Manage rules but ignore specific groups
resource "loki_rules" "ignore_example" {
  namespace = "dev-namespace"

  content_file = "${path.module}/all-rules.yaml"

  # Manage all groups except testing groups
  ignore_groups = ["test-alerts", "experimental-rules"]
}

# Multi-tenant example
resource "loki_rules" "multi_tenant" {
  namespace = "team-a-alerts"
  org_id    = "tenant-1"

  content = <<EOT
groups:
  - name: team-a-production
    interval: 1m
    rules:
      - alert: ApplicationError
        expr: 'sum(rate({app="team-a-app"} |= "ERROR" [5m])) > 10'
        for: 5m
        labels:
          severity: warning
          team: team-a
        annotations:
          summary: High error rate in team-a application
EOT
}
