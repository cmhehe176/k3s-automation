# Design Spec: OpenShift Console Standalone with Dex OIDC Authentication on K3s

- **Date:** 2026-08-17
- **Status:** Approved
- **Target Repository:** `k3s-automation/ansible`

---

## 1. Overview & Goals

This specification defines the architecture, user management, and Ansible automation for deploying **OpenShift Web Console** with a native **Dex OpenID Connect (OIDC)** authentication server on a **K3s** cluster.

### Key Goals
1. **Native Web Login Form:** Provide an authentic, browser-based login screen (Email/Username & Password) before granting access to OpenShift Console.
2. **Multi-User & Role-Based Access Control (RBAC):** Support configuring multiple accounts with distinct roles (`admins` for full `cluster-admin`, `developers` for namespace-scoped `edit`, `viewers` for read-only access).
3. **Seamless User Management:** Allow adding, updating, or removing users simply by editing `vars/users.yml` and running `./cluster.sh console deploy`.
4. **Lightweight & Self-Contained:** Use Dex OIDC (~25MB RAM footprint) and direct NodePort networking (`30900` for Console, `32000` for Dex) without requiring external DNS or heavy ingress setups.

---

## 2. Architecture & Component Details

```
+-----------------------------------------------------------------------------------------+
|                                    User Web Browser                                     |
+-----------------------------------------------------------------------------------------+
       | (1) Access http://<host>:30900                      | (3) Fill User/Password Form
       v                                                     v
+-----------------------------+               +-----------------------------+
|    OpenShift Web Console    |   (2) Redir   |       Dex OIDC Server       |
|    (NodePort: 30900)        | ------------> |    (NodePort: 32000)        |
+-----------------------------+ <------------ +-----------------------------+
       |                               (4) Return JWT ID Token
       v
+-----------------------------------------------------------------------------------------+
|                                    K3s Control Plane                                    |
|                                                                                         |
|  * K3s API Server: Configured with OIDC flags to validate Dex JWT tokens:              |
|      - oidc-issuer-url: http://<node_ip>:32000                                          |
|      - oidc-client-id: openshift-console                                                |
|      - oidc-username-claim: email                                                       |
|      - oidc-groups-claim: groups                                                        |
|                                                                                         |
|  * RBAC Bindings:                                                                       |
|      - Group "admins"     --> ClusterRole: cluster-admin                                |
|      - Group "developers" --> ClusterRole: edit (in default / dev namespaces)            |
|      - Group "viewers"    --> ClusterRole: view (in default / dev namespaces)           |
+-----------------------------------------------------------------------------------------+
```

### Components Deployed in Namespace `openshift-console`:

1. **Dex OIDC Server (`dexidp/dex:v2.41.0`):**
   - **Service & Ports:** Listens on port `5556`, exposed via NodePort `32000`.
   - **ConfigMap `dex-config`:**
     - `issuer`: `http://<node_ip>:32000`
     - `storage`: `kubernetes` or `memory`
     - `web.http`: `0.0.0.0:5556`
     - `staticClients`: client `openshift-console`, secret `<console_client_secret>`, redirectURI `http://<node_ip>:30900/auth/callback`
     - `staticUsers`: List of users rendered with Bcrypt password hashes and associated groups.

2. **OpenShift Console (`quay.io/openshift/origin-console:latest`):**
   - **Service & Ports:** Exposed via NodePort `30900`.
   - **Environment:**
     - `BRIDGE_USER_AUTH`: `oidc`
     - `BRIDGE_USER_AUTH_OIDC_ISSUER_URL`: `http://<node_ip>:32000`
     - `BRIDGE_USER_AUTH_OIDC_CLIENT_ID`: `openshift-console`
     - `BRIDGE_USER_AUTH_OIDC_CLIENT_SECRET`: `<console_client_secret>`
     - `BRIDGE_BASE_ADDRESS`: `http://<node_ip>:30900`
     - `BRIDGE_K8S_MODE`: `in-cluster`
     - `BRIDGE_LISTEN`: `http://0.0.0.0:9000`

3. **K3s OIDC Configuration:**
   - Ensure K3s API server is configured with OIDC parameters in `/etc/rancher/k3s/config.yaml` to accept Dex JWT tokens.

4. **RBAC Resource Definitions:**
   - `ClusterRoleBinding` `dex-admins-binding`: Subject group `admins` $\rightarrow$ `ClusterRole: cluster-admin`.
   - `RoleBinding` `dex-developers-binding`: Subject group `developers` $\rightarrow$ `ClusterRole: edit` in specified namespaces.
   - `RoleBinding` `dex-viewers-binding`: Subject group `viewers` $\rightarrow$ `ClusterRole: view`.

---

## 3. User Configuration (`openshift-console/vars/users.yml`)

Users are managed via a dedicated YAML file:

```yaml
console_oidc_issuer_port: 32000
console_web_nodeport: 30900
console_client_secret: "OpenShiftConsoleSecretKey2026"

console_users:
  - username: "admin"
    email: "admin@ndmc.pro"
    password: "AdminPassword123!"
    groups:
      - "admins"

  - username: "developer"
    email: "dev@ndmc.pro"
    password: "DevPassword123!"
    groups:
      - "developers"
```

---

## 4. Automation & Ansible Implementation Flow

### Playbooks & Files Structure
```
openshift-console/
├── vars/
│   └── users.yml                     # User accounts, passwords & groups
├── templates/
│   ├── dex.yaml.j2                   # Dex Deployment, ConfigMap, Service, SA, RBAC
│   ├── openshift-console.yaml.j2     # Console Deployment & Service
│   └── rbac.yaml.j2                  # OIDC Group-to-ClusterRole mappings
├── playbooks/
│   ├── deploy.yml                    # Master deploy playbook (Bcrypt hash generation, K3s OIDC config, manifests apply)
│   └── uninstall.yml                 # Cleanup playbook
└── scripts/
    ├── deploy-console.sh
    └── uninstall-console.sh
```

---

## 5. Verification & Testing

1. **Dex OIDC Health Check:** Verify `curl -s http://<node_ip>:32000/.well-known/openid-configuration` returns valid JSON OIDC discovery doc.
2. **Login Flow:** Open `http://<node_ip>:30900` in browser $\rightarrow$ redirected to Dex login screen $\rightarrow$ submit `admin@ndmc.pro` $\rightarrow$ redirected back to OpenShift Console with admin rights.
3. **Role Boundary Check:** Log in with `dev@ndmc.pro` $\rightarrow$ verify access is restricted to allowed namespaces.
