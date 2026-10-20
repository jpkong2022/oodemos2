namespace: ai2
flow:
  name: TestFlow
  workflow:
    - sleep:
        do:
          io.cloudslang.base.utils.sleep:
            - seconds: '1'
        navigate:
          - SUCCESS: SUCCESS
          - FAILURE: on_failure
  results:
    - FAILURE
    - SUCCESS
