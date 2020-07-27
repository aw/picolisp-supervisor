#!/usr/bin/env pil
#
# Unicorn-inspired PicoLisp daemon to spawn and manage worker processes
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

[de APP_HELP
  ("usage"     "./supervisor.l --app <yourapp> [option] [arguments]")
  ("example"   "./supervisor.l --app app.l --workers 4 --poll 1^J")
  ("options"   ("--help"      "show this help message and exit")
               ()
               ("--app <yourapp>"       "Filename of the app which contains (worker-start)")
               ("--poll <seconds>"      "Number of seconds to poll for missing workers (default: 30)")
               ("--preload"             "Load the app in the parent before forking the worker process (default: No)")
               ("--workers <number>"    "Number of workers to spawn (default: 1)") ]

# INITIALIZE
(setq
  *SV_PR_SET_NAME  15
  *SV_POLL_TIMEOUT 30
  *SV_MAX_WORKERS   1 )

(off
  *SV_WORKERS
  *SV_PRELOAD_APP )

# LOAD
(chdir (car (file)) (load "clihelpers.l" "module.l"))

# MAIN
[de sv-parent-sleep ()
  (wait (* 1000 *SV_POLL_TIMEOUT) ]                        # pause for *SV_POLL_TIMEOUT seconds

# Perform some cleanup tasks in the worker process (child)
[de sv-cleanup-worker (Num)
  (sv-print (sv-child-name Num) " exited") ]

# Things to run after forking the worker
# The (load)'ed worker code CAN DEFINE its own (after-fork) function which
# will be called here.
[de sv-after-fork (Num)
  (sv-print (sv-child-name Num) " spawned pid=" *Pid)
  (when after-fork (after-fork Num) ]                      # run tasks after forking the worker

# Perform some initial work in the child process
[de sv-init-worker-process (Num)
  (sv-proc-name (pack "worker[" Num "]"))
  (sv-after-fork Num) ]                                    # always run this after forking

# Run a loop inside each worker
# The (load)'ed worker code MUST DEFINE its own (worker-start) function which
# will be called here.
[de sv-worker-loop (Num)
  (sv-init-worker-process Num)                             # initial tasks before looping

  (finally
    (sv-cleanup-worker Num)                                # cleanup once the worker exits
    (catch 'sv-error
      (sv-print (sv-child-name Num) " ready")
      (loop                                                # loop forever
        (worker-start Num)                                 # start the worker
        (unless (kill *PPid 0) (bye)) )                    # exit the loop if the parent is gone
      NIL ]

# Seed some random data in each forked process
[de sv-after-fork-internal ()
  (seed (in "/dev/urandom" (rd 20) ]

# Child process which does work
[de sv-child (Num)
  (unless *SV_PRELOAD_APP (load *SV_APP))                  # load the worker code in the child
  (sv-after-fork-internal)                                 # internal tasks to run before looping
  (sv-worker-loop Num)                                     # loop on some work
  (bye) ]                                                  # R.I.P.

# Parent process which manages the workers (children)
[de sv-parent (Num)
  (queue '*SV_WORKERS (cons @ Num) ]                       # add the worker to a list

# Things to run before forking the worker
# The (load)'ed worker code CAN DEFINE its own (before-fork) function which
# will be called here.
[de sv-before-fork (Num)
  (sv-print (sv-child-name Num) " spawning..")
  (when before-fork (before-fork Num) ]                    # run tasks before forking the worker

# Get the process ID of the worker process (child)
[de sv-worker-pid (Num)
  (car (rassoc Num *SV_WORKERS)) ]

# Spawn workers to get the count up-to-date
[de sv-spawn-missing-workers ()
  (let Worker_nr -1
    (until (= (inc 'Worker_nr) *SV_MAX_WORKERS)
      (unless (sv-worker-pid Worker_nr)                    # only if its Pid is in our list
        (sv-before-fork Worker_nr)
        (if (fork)
            (sv-parent Worker_nr)                          # parent process
            (sv-child Worker_nr) ]                         # child process

# Compare how many workers we have with the amount of workers there should be
[de sv-maintain-worker-count ()
  (when (lt0 (- (length *SV_WORKERS) *SV_MAX_WORKERS))
        (sv-print "spawning " (abs @) " missing workers: ")
        (sv-spawn-missing-workers) ) ]                     # spawn if there's at least 1 missing

# Give a unique name to each worker process (child)
[de sv-child-name (Num)
  (pack "worker[" Num "]") ]

# Remove the worker from the list and ensure it exited
[de sv-reap-worker (N)
  (setq *SV_WORKERS (delete N *SV_WORKERS))
  (kill (car N))
  (sv-print "reaped " (car N) " " (sv-child-name (cdr N) ]

# Tries to reap all unreaped workers
[de sv-reap-all-workers ()
  (wait 1)
  (mapcar '((N)
          (unless (member (car N) (kids))                  # only if the worker is in our list
            (sv-reap-worker N) ) )                         # reap this worker
          *SV_WORKERS ]

# Parent loop
[de sv-parent-loop ()
  (sv-reap-all-workers)                                    # check for unreaped workers
  (case (fifo '*SV_SIG_QUEUE)                              # TODO: add support for "signals"
    (NIL (when Respawn                                     # only spawn workers when Respawn is T
              (sv-maintain-worker-count))                  # ensure there's enough workers
          (sv-parent-sleep) ]                              # sleep after spawning workers

# Perform some cleanup tasks in the parent process
[de sv-cleanup-parent ()
  (sv-print "parent exited") ]

# Set the process name of the parent or child
[de sv-proc-name (Name)
  (when (== 64 64)
        (cond ((= *OS "Linux")    (native "@" "prctl" NIL *SV_PR_SET_NAME Name))
              ((= *OS "FreeBSD")  (native "@" "setproctitle" NIL "%s" Name))
              (T NIL) ]

# Print a message to STDOUT with timestamp
[de sv-print @
  (prinl "[" (dat$ (date) "-") "T" (tim$ (time) T) "] " (rest) ]

# Start the parent process
[de sv-parent-start ()
  (on Respawn)

  (sv-proc-name "parent")
  (sv-print "parent process ready pid=" *Pid)

  (when *SV_PRELOAD_APP (load *SV_APP))                    # load the worker code in the parent

  (finally
    (sv-cleanup-parent)                                    # cleanup once the parent exits
    (loop (sv-parent-loop) ]                               # start the loop for the parent process

[ifn  (argv)
      (sv-show-help)
      (while (opt)
        (case @
          (--app    (setq *SV_APP (opt)))                  # required
          (--poll   (setq *SV_POLL_TIMEOUT (format (opt))))# default '30'
          (--workers (setq *SV_MAX_WORKERS (format (opt))))# default '1'
          (--preload (on *SV_PRELOAD_APP))                 # preload the app?
          (T        (sv-show-help) (bye 1)) ) )            # show help and exit

      (finally (unless (=T @) (bye 1))
        (catch 'sv-error
          (sv-parent-start) ]                              # start running the parent process

(bye)
