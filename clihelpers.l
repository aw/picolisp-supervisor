# picolisp-supervisor - https://github.com/aw/picolisp-supervisor
#
# Command-line tool helpers
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

### HELPERS
[de sv-options (N)
  (tab  (2 -22 5) " " (car N) (cdr N) ]

[de sv-show-help ()
  (prinl
    (cdr (assoc "name" APP_INFO)) " v" (cdr (assoc "version" APP_INFO)) "^J"
    "Copyright " (cdr (assoc "copyright" APP_INFO)) "^J"
    (cdr (assoc "source" APP_INFO)) "^J"
    "License " (cdr (assoc "license" APP_INFO)) "^J^J"
    (cdr (assoc "summary" APP_INFO)) "^J^J"
    (sv-options (list "Usage:" (cdr (assoc "usage" APP_HELP)))) "^J"
    (sv-options (list "Example:" (cdr (assoc "example" APP_HELP))))
    (sv-options (list "Options:"))
    (mapcar sv-options (cdr (assoc "options" APP_HELP))) ]

# Send error message to STDERR
[de sv-throw (Error)
  (msg Error)
  (setq *Msg Error)
  (throw 'sv-error Error) ]
