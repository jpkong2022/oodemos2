namespace: ai2
flow:
  name: create_office365_user
  workflow:
    - get_token:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: 'https://login.microsoftonline.com/z1jfl.onmicrosoft.com/oauth2/v2.0/token'
            - body: 'client_id=fdba704b-86b6-4b64-b679-3f6f951216b0&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default&client_secret=fzA8Q~FL~3o6EQbLt6~nobcmpkIpKTddB_SDVcxB&grant_type=client_credentials'
            - content_type: application/x-www-form-urlencoded
        publish:
          - json: '${return_result}'
        navigate:
          - SUCCESS: extract_token
          - FAILURE: on_failure
    - extract_token:
        do:
          io.cloudslang.base.json.json_path_query:
            - json_object: '${json}'
            - json_path: $.access_token
        publish:
          - token: '${return_result[1:-1]}'
        navigate:
          - SUCCESS: create_user
          - FAILURE: on_failure
    - create_user:
        do:
          io.cloudslang.base.http.http_client_post:
            - url: 'https://graph.microsoft.com/v1.0/users'
            - headers: "${'Authorization: Bearer ' + token}"
            - body: '{"accountEnabled": true, "displayName": "New CloudSlang User", "mailNickname": "csnewuser", "userPrincipalName": "csnewuser@z1jfl.onmicrosoft.com", "passwordProfile": {"forceChangePasswordNextSignIn": true, "password": "StrongPassword123!"}}'
            - content_type: application/json
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - SUCCESS
    - FAILURE
