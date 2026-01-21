name: Bug Report
description: Report a bug or issue
title: "[BUG] "
labels: [bug, needs-triage]

body:
  - type: textarea
    id: description
    attributes:
      label: Description
      description: Clear description of the issue
    validations:
      required: true

  - type: textarea
    id: steps
    attributes:
      label: Steps to Reproduce
      description: |
        1. First step
        2. Second step
        3. ...
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What should happen
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: Actual Behavior
      description: What actually happens
    validations:
      required: true

  - type: textarea
    id: environment
    attributes:
      label: Environment
      description: |
        - Flutter version: (run `flutter --version`)
        - Device: iOS/Android model
        - OS: iOS/Android version
        - App version:
    validations:
      required: true

  - type: textarea
    id: logs
    attributes:
      label: Logs/Screenshots
      description: Attach error logs or screenshots
