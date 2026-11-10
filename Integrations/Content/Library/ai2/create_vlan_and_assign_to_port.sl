namespace: ai2
flow:
  name: create_vlan_and_assign_to_port
  inputs:
    - ucs_host
    - username
    - password:
        sensitive: true
    - vlan_name
    - vlan_id
    - fi_id:
        default: 'A'
    - slot_id:
        default: '1'
    - port_id
  workflow:
    - configure_ucs_vlan:
        do:
          io.cloudslang.base.python.python_script:
            - script: |
                import urllib.request
                import ssl
                import xml.etree.ElementTree as ET
                import sys
                
                ucs_host = "${ucs_host}"
                username = "${username}"
                password = "${password}"
                vlan_name = "${vlan_name}"
                vlan_id = "${vlan_id}"
                fi_id = "${fi_id}"
                slot_id = "${slot_id}"
                port_id = "${port_id}"
                
                ctx = ssl.create_default_context()
                ctx.check_hostname = False
                ctx.verify_mode = ssl.CERT_NONE
                
                url = f"https://{ucs_host}/nuova"
                
                # 1. Login to UCS Manager XML API
                login_xml = f'<aaaLogin inName="{username}" inPassword="{password}"></aaaLogin>'
                req = urllib.request.Request(url, data=login_xml.encode('utf-8'), headers={'Content-Type': 'application/xml'})
                res = urllib.request.urlopen(req, context=ctx)
                root = ET.fromstring(res.read())
                cookie = root.attrib.get('outCookie')
                
                if not cookie:
                    print("Login failed: " + root.attrib.get('outError', 'Unknown error'))
                    sys.exit(1)
                
                try:
                    # 2. Create VLAN in the LAN Cloud
                    vlan_dn = f"fabric/lan/net-{vlan_name}"
                    vlan_xml = f'''<configConfMo cookie="{cookie}" dn="{vlan_dn}">
                        <inConfig>
                            <fabricVlan defaultNet="no" dn="{vlan_dn}" id="{vlan_id}" name="{vlan_name}" pubNwName="" sharing="none" status="created"/>
                        </inConfig>
                    </configConfMo>'''
                    req = urllib.request.Request(url, data=vlan_xml.encode('utf-8'), headers={'Content-Type': 'application/xml'})
                    urllib.request.urlopen(req, context=ctx)
                    
                    # 3. Assign VLAN to Physical Port on Fabric Interconnect
                    port_vlan_dn = f"fabric/lan/{fi_id}/phys-slot-{slot_id}-port-{port_id}/vlan-{vlan_name}"
                    assign_xml = f'''<configConfMo cookie="{cookie}" dn="{port_vlan_dn}">
                        <inConfig>
                            <fabricEthVlanEp dn="{port_vlan_dn}" name="{vlan_name}" adminState="enabled" status="created"/>
                        </inConfig>
                    </configConfMo>'''
                    req = urllib.request.Request(url, data=assign_xml.encode('utf-8'), headers={'Content-Type': 'application/xml'})
                    urllib.request.urlopen(req, context=ctx)
                    
                    print(f"Successfully created VLAN {vlan_name} and assigned to FI {fi_id} Slot {slot_id} Port {port_id}.")
                
                except Exception as e:
                    print(f"Error occurred: {str(e)}")
                    sys.exit(1)
                
                finally:
                    # 4. Logout
                    logout_xml = f'<aaaLogout inCookie="{cookie}"></aaaLogout>'
                    req = urllib.request.Request(url, data=logout_xml.encode('utf-8'), headers={'Content-Type': 'application/xml'})
                    urllib.request.urlopen(req, context=ctx)
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
