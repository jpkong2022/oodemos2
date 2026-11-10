namespace: ai2
flow:
  name: create_server_profile_template
  inputs:
    - ov_appliance_ip: 'oneview.local'
    - ov_username: 'administrator'
    - ov_password:
        value: 'Password123!'
        sensitive: true
    - template_name: 'CRM_Server_Profile_Template'
    - server_hardware_type: 'SY 480 Gen10 1'
    - enclosure_group: 'Prod_Enclosure_Group'
  workflow:
    - create_template:
        do:
          io.cloudslang.base.powershell.powershell_script:
            - host: '172.31.34.122'
            - port: '5985'
            - protocol: http
            - username: administrator
            - password:
                value: "${get_sp('winserver1_admin_pwd')}"
                sensitive: true
            - auth_type: basic
            - script: |
                $ErrorActionPreference = "Stop"
                $ov_appliance = "${ov_appliance_ip}"
                $ov_user = "${ov_username}"
                $ov_pass = "${ov_password}"
                $template = "${template_name}"
                $hw_type = "${server_hardware_type}"
                $eg = "${enclosure_group}"

                Write-Host "Connecting to HPE OneView Appliance: $ov_appliance"
                Connect-HPOVMgmt -Appliance $ov_appliance -Username $ov_user -Password $ov_pass

                Write-Host "Creating Server Profile Template: $template"
                New-HPOVServerProfileTemplate -Name $template -ServerHardwareType $hw_type -EnclosureGroup $eg
                
                Write-Host "Successfully created server profile template."
                Disconnect-HPOVMgmt
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
