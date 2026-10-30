namespace: ai2
flow:
  name: restart_crm_db_spooler_service
  workflow:
    - restart_spooler_service:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: 172.31.43.41
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('dbserver_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: "Restart-Service -Name 'spooler'"
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
