namespace: ai2
flow:
  name: create_ucs_vlan_and_assign
  inputs:
    - ucs_host: '10.0.0.10'
    - ucs_username: 'admin'
    - ucs_password:
        value: 'Admin123!'
        sensitive: true
    - vlan_id: '100'
    - vlan_name: 'VLAN100'
    - fi_id: 'A'
    - slot_id: '1'
    - port_id: '10'
  workflow:
    - execute_ucs_powertool:
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
                
                $ucsHost = "${ucs_host}"
                $ucsUser = "${ucs_username}"
                $ucsPass = "${ucs_password}"
                $vlanId = "${vlan_id}"
                $vlanName = "${vlan_name}"
                $fiId = "${fi_id}"
                $slotId = "${slot_id}"
                $portId = "${port_id}"

                $secPassword = ConvertTo-SecureString $ucsPass -AsPlainText -Force
                $cred = New-Object System.Management.Automation.PSCredential ($ucsUser, $secPassword)
                
                try {
                    Connect-Ucs -Name $ucsHost -Credential $cred -WarningAction SilentlyContinue | Out-Null
                    
                    Write-Host "Creating VLAN $vlanName ($vlanId) in LAN Cloud..."
                    Get-UcsLanCloud | Add-UcsVlan -Id $vlanId -Name $vlanName -McastPolicyName "default" -Force
                    
                    Write-Host "Assigning VLAN $vlanName to Fabric Interconnect $fiId Slot $slotId Port $portId..."
                    $fiPort = Get-UcsEtherServerIntFiEp -SwitchId $fiId -SlotId $slotId -PortId $portId
                    
                    if ($fiPort) {
                        $fiPort | Add-UcsVlan -Name $vlanName -Force
                        Write-Host "VLAN successfully assigned to the physical server port."
                    } else {
                        Write-Error "Fabric Interconnect physical server port not found."
                        exit 1
                    }
                } catch {
                    Write-Error "Error executing UCS commands: $_"
                    exit 1
                } finally {
                    Disconnect-Ucs -WarningAction SilentlyContinue | Out-Null
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
