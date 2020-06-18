# Supervisor tests

[de tests-execute ()
  (assert-t (kill (car *Parent_pid) 0) "The supervisor should be running")
  (wait 1000)
  (assert-t (kill (car *Parent_pid)) "The supervisor should exit cleanly")
  ]

[de tests-supervisor ()
  (setq *Parent_pid (kids))

  (execute
    '(tests-execute) ]

[chdir ".."
  (tests-supervisor) ]

(wait 1000)
(prinl)
