account_sites
- id
- account_id
- site_id
- active
- created_by
- ip
- request_id
- created_at
- updated_at

[x] sites
- id
- name:uniq
- site_stat_id
- site_group_id
- created_by
- ip
- request_id
- created_at
- updated_at

[x] accounts
- id
- username:uniq
- name
- email
- password_digest
- active:boolean
- role_id
- created_by
- ip
- request_id
- created_at
- updated_at


[x] site_stats
- id
- name:unique
- description
- created_by
- ip
- request_id
- created_at
- updated_at

[x] site_groups
- id
- name:unique
- description
- project_id
- created_by
- ip
- request_id
- created_at
- updated_at

[x] projects
- id
- name:unique
- description
- created_by
- ip
- request_id
- created_at
- updated_at


[x] function_accesses
- id
- code
- label
- path
- description
- admin
- active:boolean
- created_by
- ip
- request_id
- created_at
- updated_at

[x] roles
- id
- name
- description
- active
- created_by
- ip
- request_id
- created_at
- updated_at

account_function_accesses
- id
- account_id
- function_access_id
- allow_create:booelan
- allow_read:boolean
- allow_update:booelan
- allow_delete:booelan
- allow_confirm:booelan
- allow_cancel_confirm:booelan
- active:booelan
- created_by
- ip
- request_id
- created_at
- updated_at

role_function_accesses
- id
- account_id
- role_id
- allow_create:booelan
- allow_read:boolean
- allow_update:booelan
- allow_delete:booelan
- allow_confirm:booelan
- allow_cancel_confirm:booelan
- active:booelan
- created_by
- ip
- request_id
- created_at
- updated_at