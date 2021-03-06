#|
  This file is a part of CL-DBI project.
  Copyright (c) 2011 Eitarow Fukamachi (e.arrows@gmail.com)
|#

(in-package :cl-user)
(defpackage dbd.mysql
  (:use :cl
        :dbi.driver
        :dbi.error
        :cl-mysql)
  (:shadowing-import-from :dbi.driver
                          :disconnect))
(in-package :dbd.mysql)

(cl-syntax:use-syntax :annot)

@export
(defclass <dbd-mysql> (<dbi-driver>) ())

@export
(defclass <dbd-mysql-connection> (<dbi-connection>) ())

(defmethod make-connection ((driver <dbd-mysql>) &key host database-name username password port socket client-flag)
  (make-instance '<dbd-mysql-connection>
     :handle (connect :host host
                      :database database-name
                      :user username
                      :password password
                      :port port
                      :socket socket
                      :client-flag client-flag)))

@export
(defclass <dbd-mysql-query> (<dbi-query>)
     ((%result :initform nil)))

(defmethod prepare ((conn <dbd-mysql-connection>) (sql string) &key)
  (call-next-method conn sql :query-class '<dbd-mysql-query>))

(defmethod execute-using-connection ((conn <dbd-mysql-connection>) (query <dbd-mysql-query>) params)
  (let ((result (query (apply (query-prepared query) params)
                       :database (connection-handle conn)
                       :store nil)))
    (cl-mysql-system::return-or-close (cl-mysql-system::owner-pool result) result)
    (next-result-set result)
    (setf (slot-value query '%result) result)
    query))

(defmethod fetch-using-connection ((conn <dbd-mysql-connection>) query)
  (loop with result = (slot-value query '%result)
        for val in (next-row result)
        for (name . type) in (car (result-set-fields result))
        append (list (intern name :keyword) val)))

(defmethod escape-sql ((conn <dbd-mysql-connection>) (sql string))
  (escape-string sql :database (connection-handle conn)))

(defmethod disconnect ((conn <dbd-mysql-connection>))
  (cl-mysql:disconnect (connection-handle conn)))

(defmethod begin-transaction ((conn <dbd-mysql-connection>))
  (do-sql conn "START TRANSACTION"))

(defmethod commit ((conn <dbd-mysql-connection>))
  (do-sql conn "COMMIT"))

(defmethod rollback ((conn <dbd-mysql-connection>))
  (do-sql conn "ROLLBACK"))
