#|
  This file is a part of CL-DBI project.
  Copyright (c) 2011 Eitarow Fukamachi (e.arrows@gmail.com)
|#

(in-package :cl-user)
(defpackage dbi.test
  (:use :cl
        :dbi
        :dbi.driver
        :cl-test-more
        :trivial-types))
(in-package :dbi.test)

(cl-syntax:use-syntax :annot)

(defparameter *db* nil)

@export
(defun run-driver-tests (driver-name &rest params)
  (let ((*db* (apply #'connect driver-name params)))
    (plan 18)
    (run-test-all)))

(deftest |connect|
  (is-type *db* '<dbi-connection>))

(deftest |do-sql|
  (is (do-sql *db* "DROP TABLE IF EXISTS person") nil)
  (is (do-sql *db* "CREATE TABLE person (id INTEGER PRIMARY KEY, name VARCHAR(24) NOT NULL)")
      nil)
  (is (do-sql *db* "INSERT INTO person (id, name) VALUES (1, 'fukamachi')")
      nil)
  (is (do-sql *db* "INSERT INTO person (id, name) VALUES (2, 'matsuyama')")
      nil))

(deftest |prepare, execute & fetch|
  (let (query result)
    (setf query (prepare *db* "SELECT * FROM person"))
    (is-type query '<dbi-query>)
    (setf result (execute query))
    (is (fetch-all result)
        '((:|id| 1 :|name| "fukamachi") (:|id| 2 :|name| "matsuyama")))
    (setf result (execute query))
    (is-type result '<dbi-query>)
    (let ((result (fetch result)))
      (is-type result '(non-nil property-list))
      (is (getf result :|name|) "fukamachi"))
    (let ((result (fetch result)))
      (is-type result '(non-nil property-list))
      (is (getf result :|name|) "matsuyama"))
    (is (fetch result) nil)))

(deftest |place holder|
  (let (query result)
    (setf query (prepare *db* "SELECT * FROM person WHERE name = ?"))
    (is-type query '<dbi-query>)
    (setf result (execute query "matsuyama"))
    (is-type result '<dbi-query>)
    (is-type (fetch result) '(non-nil property-list))
    (is (fetch result) nil)))

(deftest |with-transaction|
  (handler-case
      (progn
        (with-transaction *db*
          (do-sql *db* "INSERT INTO person (id, name) VALUES (3, 'meymao')"))
        (is (fetch (execute (prepare *db* "SELECT * FROM person WHERE name = 'meymao'")))
            '(:|id| 3 :|name| "meymao")))
    (dbi.error:<dbi-notsupported-error> (condition)
     (skip 1 "Not supported"))))
