namespace: ai2
flow:
  name: stop_spooler_on_winserver1
  workflow:
    - stop_spooler_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.34.122
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('winserver1_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: "Stop-Service -Name 'spooler' -Force"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
