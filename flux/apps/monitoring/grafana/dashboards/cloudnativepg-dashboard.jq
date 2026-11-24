# Grafana.com revision 4 predates the Barman Cloud plugin metrics. Adapt the
# backup panels and datasource defaults for the locally provisioned dashboard.
walk(
  if type == "object" and (.expr? | type) == "string" then
    .expr |= (
      gsub("cnpg_collector_last_available_backup_timestamp"; "barman_cloud_cloudnative_pg_io_last_available_backup_timestamp") |
      gsub("cnpg_collector_first_recoverability_point"; "barman_cloud_cloudnative_pg_io_first_recoverability_point") |
      gsub("cloudnative-pg-operator[.]\\+\\|cnpg-controller-manager[.]\\+"; "cloudnative-pg-operator.+|cnpg-controller-manager.+|postgres-operator-cloudnative-pg.+")
    )
  elif type == "object" and .uid? == "${DS_EXPRESSION}" then
    .uid = "__expr__"
  elif type == "object" and .uid? == "prometheus" then
    .uid = "victoria-metrics-prometheus"
  else . end
) |
(.templating.list[] | select(.name == "DS_PROMETHEUS") | .current) = {
  "selected": false,
  "text": "Victoria-Metrics (Prometheus API)",
  "value": "victoria-metrics-prometheus"
}
