resource "keycloak_group_roles" "cloud_roles" {
  realm_id = keycloak_realm.my_test_realm.id
  group_id = keycloak_group.cloud.id

  role_ids = [
    keycloak_role.grafana.id,
  ]
}
