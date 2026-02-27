resource "keycloak_group" "cloud" {
  realm_id = keycloak_realm.my_test_realm.id
  name     = "cloud"
}

resource "keycloak_group" "security" {
  realm_id  = keycloak_realm.my_test_realm.id
  name      = "security"
  parent_id = keycloak_group.cloud.id
}
