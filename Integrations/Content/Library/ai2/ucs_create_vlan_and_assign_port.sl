namespace: ai2
flow:
  name: ucs_create_vlan_and_assign_port
  inputs:
    - ucs_host: '10.0.0.10'
    - ucs_user: 'admin'
    - ucs_pwd:
        value: "${get_sp('ucs_admin_pwd')}"
        sensitive: true
    - vlan_name: 'VLAN-100'
    - vlan_id: '100'
    - fabric_id: 'A'
    - slot_id: '1'
    - port_id: '5'
  workflow:
    - execute_ucs_powershell_script:
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
            - script: |
                Import-Module Cisco.UcsManager
                $securePwd = ConvertTo-SecureString -String '${ucs_pwd}' -AsPlainText -Force
                $cred = New-Object System.Management.Automation.PSCredential ('${ucs_user}', $securePwd)
                
                try {
                    Connect-Ucs -Name '${ucs_host}' -Credential $cred | Out-Null
                    Write-Host "Successfully connected to UCS Manager: ${ucs_host}"
                    
                    # Create a new VLAN in the LAN cloud
                    $lanCloud = Get-UcsLanCloud
                    $lanCloud | Add-UcsVlan -Name '${vlan_name}' -Id '${vlan_id}' -DefaultNet 'no' -Sharing 'none' -ModifyPresent | Out-Null
                    Write-Host "VLAN ${vlan_name} (ID: ${vlan_id}) created in the LAN cloud."
                    
                    # Assign the VLAN to a physical port on the Fabric Interconnect
                    $portDn = "fabric/lan/${fabric_id}/phys-slot-${slot_id}-port-${port_id}"
                    $fabricEp = Get-UcsFabricEp -Dn $portDn
                    
                    if ($fabricEp) {
                        $fabricEp | Add-UcsSwEthLanEp -Name '${vlan_name}' -ModifyPresent | Out-Null
                        Write-Host "VLAN ${vlan_name} successfully assigned to physical port ${portDn}."
                    } else {
                        Write-Error "Physical port ${portDn} not found on the Fabric Interconnect."
                        exit 1
                    }
                } catch {
                    Write-Error "An error occurred during UCS configuration: $_"
                    exit 1
                } finally {
                    Disconnect-Ucs | Out-Null
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
