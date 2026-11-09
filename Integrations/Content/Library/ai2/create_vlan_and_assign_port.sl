namespace: ai2
flow:
  name: create_vlan_and_assign_port
  inputs:
    - ucs_host: "172.31.40.10"
    - ucs_username: "admin"
    - ucs_password:
        value: "${get_sp('ucs_admin_pwd')}"
        sensitive: true
    - vlan_id: "100"
    - vlan_name: "VLAN100"
    - fi_id: "A"
    - slot_id: "1"
    - port_id: "5"
  workflow:
    - login_to_ucs:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${ 'https://' + ucs_host + '/nuova' }"
            - body: "${ '<aaaLogin inName=\"' + ucs_username + '\" inPassword=\"' + ucs_password + '\"/>' }"
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
        publish:
          - ucs_cookie: "${ return_result.split('outCookie=\"')[1].split('\"')[0] }"
        navigate:
          - SUCCESS: create_lan_vlan
          - FAILURE: on_failure

    - create_lan_vlan:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${ 'https://' + ucs_host + '/nuova' }"
            - body: >
                ${ '<configConfMo cookie=\"' + ucs_cookie + '\" dn=\"fabric/lan/net-' + vlan_name + '\" inHierarchical=\"false\"><inConfig><fabricVlan dn=\"fabric/lan/net-' + vlan_name + '\" id=\"' + vlan_id + '\" name=\"' + vlan_name + '\"/></inConfig></configConfMo>' }
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
        navigate:
          - SUCCESS: assign_vlan_to_port
          - FAILURE: logout_on_failure

    - assign_vlan_to_port:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${ 'https://' + ucs_host + '/nuova' }"
            - body: >
                ${ '<configConfMo cookie=\"' + ucs_cookie + '\" dn=\"fabric/server/sw-' + fi_id + '/slot-' + slot_id + '/port-' + port_id + '\" inHierarchical=\"false\"><inConfig><fabricEthVlanPc dn=\"fabric/server/sw-' + fi_id + '/slot-' + slot_id + '/port-' + port_id + '/vlan-' + vlan_name + '\" name=\"' + vlan_name + '\"/></inConfig></configConfMo>' }
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
        navigate:
          - SUCCESS: logout_from_ucs
          - FAILURE: logout_on_failure

    - logout_from_ucs:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${ 'https://' + ucs_host + '/nuova' }"
            - body: "${ '<aaaLogout inCookie=\"' + ucs_cookie + '\"/>' }"
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS

    - logout_on_failure:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: "${ 'https://' + ucs_host + '/nuova' }"
            - body: "${ '<aaaLogout inCookie=\"' + ucs_cookie + '\"/>' }"
            - content_type: 'application/xml'
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
        navigate:
          - SUCCESS: FAILURE
          - FAILURE: FAILURE

  results:
    - SUCCESS
    - FAILURE
