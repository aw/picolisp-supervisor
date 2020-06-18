# picolisp-supervisor - https://github.com/aw/picolisp-supervisor
#
# Example worker which sleeps for a random number of seconds
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

[de before-fork (Num)
  (prinl "parent pid=" *Pid " do this before forking") ]

[de after-fork (Num)
  (prinl "worker[" Num "] pid=" *Pid " do this after forking") ]

[de worker-start (Num)
  (let (Sleep (rand 5 20)
        Task '(call 'sleep Sleep) )

    (prinl "worker[" Num "] pid=" *Pid " Performing a task: sleeping for " Sleep " seconds")
    (eval Task) ]
