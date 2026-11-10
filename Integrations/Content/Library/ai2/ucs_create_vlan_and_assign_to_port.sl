namespace: ai2
flow:
  name: ucs_create_vlan_and_assign_to_port
  workflow:
    - execute_ucs_powershell:
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
                Import-Module Cisco.UCSManager

                $ucsAddress = "ucs-manager-ip-or-hostname"
                $ucsUser = "admin"
                $ucsPassword = "ucs_password" | ConvertTo-SecureString -AsPlainText -Force
                $credentials = New-Object System.Management.Automation.PSCredential($ucsUser, $ucsPassword)

                try {
                    $session = Connect-Ucs -Name $ucsAddress -Credential $credentials -NotDefault
                    
                    $vlanName = "VLAN-100"
                    $vlanId = "100"
                    
                    Write-Host "Creating new VLAN $vlanName in the LAN cloud..."
                    $lanCloud = Get-UcsLanCloud -Ucs $session
                    $vlan = $lanCloud | Add-UcsVlan -Name $vlanName -Id $vlanId -DefaultNet "no" -Ucs $session
                    
                    $fabricId = "A"
                    $slotId = "1"
                    $portId = "15"
                    
                    Write-Host "Assigning VLAN $vlanName to physical server port (Fabric $fabricId, Slot $slotId, Port $portId)..."
                    $fiPort = Get-UcsSwEthLanEp -FabricId $fabricId -SlotId $slotId -PortId $portId -Ucs $session
                    if ($fiPort) {
                        $fiPort | Add-UcsSwEthLanEpVlan -Name $vlanName -Ucs $session
                        Write-Host "VLAN successfully assigned to the Fabric Interconnect port."
                    } else {
                        Write-Error "Fabric Interconnect port not found."
                        exit 1
                    }
                } catch {
                    Write-Error "An error occurred during UCS configuration: $_"
                    if ($session) { Disconnect-Ucs -Ucs $session }
                    exit 1
                }

                if ($session) {
                    Disconnect-Ucs -Ucs $session
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
