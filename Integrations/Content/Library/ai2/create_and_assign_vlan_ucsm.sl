namespace: ai2
flow:
  name: create_and_assign_vlan_ucsm
  inputs:
    - ucs_host
    - ucs_username
    - ucs_password:
        sensitive: true
    - vlan_name
    - vlan_id
    - fabric_id
    - slot_id
    - port_id
  workflow:
    - ucs_login:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: "${'<aaaLogin inName=\"' + ucs_username + '\" inPassword=\"' + ucs_password + '\"/>'}"
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        publish:
          - login_result: "${return_result}"
          - cookie: "${login_result.split('outCookie=\"')[1].split('\"')[0] if 'outCookie=\"' in login_result else ''}"
        navigate:
          - SUCCESS: create_vlan
          - FAILURE: on_failure

    - create_vlan:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: >
                ${'<configConfMo cookie=\"' + cookie + '\" dn=\"fabric/lan/net-' + vlan_name + '\" inHierarchical=\"false\"><inConfig><fabricVlan dn=\"fabric/lan/net-' + vlan_name + '\" id=\"' + vlan_id + '\" name=\"' + vlan_name + '\"/></inConfig></configConfMo>'}
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: assign_vlan_to_port
          - FAILURE: ucs_logout_failure

    - assign_vlan_to_port:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: >
                ${'<configConfMo cookie=\"' + cookie + '\" dn=\"fabric/server/sw-' + fabric_id + '/slot-' + slot_id + '-port-' + port_id + '/vlan-' + vlan_name + '\" inHierarchical=\"false\"><inConfig><swVlan dn=\"fabric/server/sw-' + fabric_id + '/slot-' + slot_id + '-port-' + port_id + '/vlan-' + vlan_name + '\" name=\"' + vlan_name + '\"/></inConfig></configConfMo>'}
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: ucs_logout
          - FAILURE: ucs_logout_failure

    - ucs_logout:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: "${'<aaaLogout inCookie=\"' + cookie + '\"/>'}"
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS

    - ucs_logout_failure:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: "${'<aaaLogout inCookie=\"' + cookie + '\"/>'}"
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: on_failure
          - FAILURE: on_failure

  results:
    - SUCCESS
    - FAILURE
