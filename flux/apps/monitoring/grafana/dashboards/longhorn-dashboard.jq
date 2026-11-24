# Set the provisioned dashboard's datasource variable without Grafana's
# interactive import step. The datasource remains selectable in the UI.
(.templating.list[] | select(.name == "datasource" and .type == "datasource") | .current) = {
  "selected": true,
  "text": "Victoria-Metrics (Prometheus API)",
  "value": "victoria-metrics-prometheus"
}
