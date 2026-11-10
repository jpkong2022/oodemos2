namespace: ai2
imports:
  http: io.cloudslang.base.http
flow:
  name: create_and_assign_vlan_ucs
  inputs:
    - ucs_host
    - username
    - password:
        sensitive: true
    - vlan_name
    - vlan_id
    - fi_id:
        default: 'A'
    - slot_id
    - port_id
  workflow:
    - login_to_ucs:
        do:
          http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: "${'<aaaLogin inName=\"' + username + '\" inPassword=\"' + password + '\"></aaaLogin>'}"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
            - content_type: 'application/xml'
        publish:
          - response_body: "${return_result}"
          - ucs_cookie: "${__import__('re').search('outCookie=\"([^\"]+)\"', return_result).group(1) if __import__('re').search('outCookie=\"([^\"]+)\"', return_result) else ''}"
        navigate:
          - SUCCESS: create_lan_vlan
          - FAILURE: on_failure

    - create_lan_vlan:
        do:
          http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: "${'<configConfMo cookie=\"' + ucs_cookie + '\" inHierarchical=\"false\" dn=\"fabric/lan/net-' + vlan_name + '\"><inConfig><fabricVlan dn=\"fabric/lan/net-' + vlan_name + '\" id=\"' + vlan_id + '\" name=\"' + vlan_name + '\"/></inConfig></configConfMo>'}"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
            - content_type: 'application/xml'
        navigate:
          - SUCCESS: assign_vlan_to_port
          - FAILURE: on_failure

    - assign_vlan_to_port:
        do:
          http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: "${'<configConfMo cookie=\"' + ucs_cookie + '\" inHierarchical=\"false\" dn=\"fabric/lan/' + fi_id + '/phys-' + slot_id + '-' + port_id + '/ep-' + vlan_name + '\"><inConfig><fabricEthVlanEp dn=\"fabric/lan/' + fi_id + '/phys-' + slot_id + '-' + port_id + '/ep-' + vlan_name + '\" name=\"' + vlan_name + '\"/></inConfig></configConfMo>'}"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
            - content_type: 'application/xml'
        navigate:
          - SUCCESS: logout_from_ucs
          - FAILURE: on_failure

    - logout_from_ucs:
        do:
          http.http_client_post:
            - url: "${'https://' + ucs_host + '/nuova'}"
            - body: "${'<aaaLogout inCookie=\"' + ucs_cookie + '\"></aaaLogout>'}"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
            - content_type: 'application/xml'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: SUCCESS

  results:
    - SUCCESS
    - FAILURE
