resource "keycloak_role" "grafana" {
  realm_id = keycloak_realm.my_test_realm.id
  name     = "grafana"
}
