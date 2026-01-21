name: Feature Request
description: Suggest a new feature
title: "[FEATURE] "
labels: [enhancement]

body:
  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: Describe the problem this feature solves
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
      description: How should this feature work?
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternative Solutions
      description: Other approaches considered

  - type: textarea
    id: context
    attributes:
      label: Additional Context
      description: Screenshots, use cases, or other info
