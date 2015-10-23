(ql:quickload :drakma)
(ql:quickload :bordeaux-threads)
(ql:quickload :rutilsx)

(in-package :cl-user)
(use-package :rutilsx)
(named-readtables:in-readtable rutils-readtable)

(let ((stdout *standard-output*)
      (base (uiop:pathname-directory-pathname
             *load-truename*)))
  (bt:make-thread
   (lambda ()
     (loop :for ch :in '(#\А #\Б #\В #\Г #\Ґ #\Д #\Э #\Є #\Е #\Ж #\З #\І
                         #\И #\К #\Л #\М #\Н #\О #\П #\Р #\С #\Т #\У #\Ф
                         #\Х #\Ц #\Ч #\Ш #\Щ #\Ю #\Я) :do
       (let ((base-dir (merge-pathnames (fmt "../raw/~A/" ch)
                                        base)))
         (ensure-directories-exist base-dir)
         (let* ((i (reduce #'max
                           (mapcar #`(parse-integer
                                      (slice (pathname-name %)
                                             (1+ (position #\- (pathname-name %)))))
                                   (directory (fmt "~A*.txt" base-dir)))
                           :initial-value 0))
                (last-ok i))
           (format stdout "~A ~A~%" ch i) (finish-output stdout)
           (loop :while (< (- i last-ok) 500) :do
             (:+ i)
             (when (zerop (rem i 100)) (princ "." stdout) (finish-output stdout))
             (let* ((key (fmt "~A-~A" ch i))
                    (raw (drakma:http-request "http://map.1551.gov.ua/data/getRequestInfo"
                                              :method :POST
                                              :user-agent nil
                                              :additional-headers `(("x-id" . ,i))
                                              :parameters `(("id" . ,key)))))
               (unless (string= raw "[{\"showStatus\":\"\",\"files\":\"\",\"feedfiles\":\"\",\"reply\":[]}]")
               (:= last-ok i)
               (with-out-file (out (merge-pathnames (fmt "../raw/~A/~A.json"
                                                         ch key)
                                                    base))
                 (write-line raw out)))))))))))
