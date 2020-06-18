#!/usr/bin/env pil

(load (pack (car (file)) ".modules/picolisp-unit/HEAD/unit.l"))

(unless (fork)
        (exec './supervisor.l "--app" "testapp.l" "--workers" 4 "--poll" 1) )

(chdir (pack (car (file)) "test/")
  (mapcar load (filter '((N) (sub? "test_" N)) (dir "."))) )

(report)
