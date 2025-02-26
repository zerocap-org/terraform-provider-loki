resource "loki_rule_group_recording" "test" {
  name      = "test1"
  namespace = "namespace1"

  # can define multiple rules
  rule {
    expr   = "max by (job) (http_inprogress_requests)"
    record = "job:http_inprogress_requests:max"
    labels      = {
      foo = "bar"
    }
  }
}
