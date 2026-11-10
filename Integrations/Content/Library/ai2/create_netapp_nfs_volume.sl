namespace: ai2
flow:
  name: create_netapp_nfs_volume
  workflow:
    - execute_netapp_powershell_script:
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
                Import-Module DataONTAP
                
                $netappHost = "172.31.10.50"
                $netappUser = "admin"
                $netappPass = "NetApp_Password123!"
                
                $securePass = ConvertTo-SecureString $netappPass -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential($netappUser, $securePass)
                
                Connect-NcController -Name $netappHost -Credential $credential
                
                $volName = "crm_nfs_shared"
                $aggrName = "aggr1"
                $volSize = "100GB"
                $junctionPath = "/crm_nfs_shared"
                $exportPolicyName = "crm_nfs_policy"
                
                New-NcExportPolicy -Name $exportPolicyName -ErrorAction SilentlyContinue
                New-NcExportRule -Policy $exportPolicyName -ClientMatch "172.31.0.0/16" -RoRule "sys" -RwRule "sys" -SuperUserSecurity "sys"
                
                New-NcVol -Name $volName -Aggregate $aggrName -Size $volSize -JunctionPath $junctionPath
                Set-NcVol -Name $volName -Policy $exportPolicyName
                
                Write-Host "NetApp NFS Shared Volume $volName created successfully and mapped to $junctionPath."
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
