namespace: ai2
flow:
  name: monitor_disk_and_kill_chrome
  workflow:
    - check_crm_db_disk_space:
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
            - script: |
                $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
                if ($disk) {
                    $freePercent = ($disk.FreeSpace / $disk.Size) * 100
                    if ($freePercent -lt 50) {
                        Write-Host "Free disk space is less than 50%"
                        exit 0
                    } else {
                        Write-Host "Free disk space is 50% or more"
                        exit 1
                    }
                } else {
                    Write-Error "Could not retrieve disk information"
                    exit 1
                }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: kill_chrome_on_winserver1
          - FAILURE: SUCCESS
    - kill_chrome_on_winserver1:
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
                Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
                Write-Host "Chrome browser processes terminated if they were running."
                exit 0
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: allow_all
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
