namespace: ai2
imports:
  http: io.cloudslang.base.http
  json: io.cloudslang.base.json
flow:
  name: hpe_oneview_instantiate_server_profile
  inputs:
    - ov_host:
        required: true
    - ov_username:
        required: true
    - ov_password:
        sensitive: true
        required: true
    - template_uri:
        required: true
    - profile_name:
        required: true
    - api_version:
        default: '1200'
        required: false
  workflow:
    - get_auth_token:
        do:
          http.http_client_action:
            - url: "${ 'https://' + ov_host + '/rest/login-sessions' }"
            - method: 'POST'
            - auth_type: 'anonymous'
            - content_type: 'application/json'
            - headers: "${ 'X-API-Version: ' + api_version }"
            - body: >
                ${ '{"userName":"' + ov_username + '","password":"' + ov_password + '"}' }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
        publish:
          - response_json: '${returnResult}'
        navigate:
          - SUCCESS: extract_token
          - FAILURE: on_failure

    - extract_token:
        do:
          json.json_path_query:
            - json_object: '${response_json}'
            - json_path: '$.sessionID'
        publish:
          - auth_token: '${return_result}'
        navigate:
          - SUCCESS: instantiate_profile
          - FAILURE: on_failure

    - instantiate_profile:
        do:
          http.http_client_action:
            - url: "${ 'https://' + ov_host + '/rest/server-profiles' }"
            - method: 'POST'
            - auth_type: 'anonymous'
            - content_type: 'application/json'
            - headers: "${ 'X-API-Version: ' + api_version + '\\r\\nauth: ' + auth_token }"
            - body: >
                ${ '{"type":"ServerProfileV12","name":"' + profile_name + '","serverProfileTemplateUri":"' + template_uri + '"}' }
            - trust_all_roots: 'true'
            - x_509_hostname_verifier: 'allow_all'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure

  results:
    - SUCCESS
    - FAILURE
