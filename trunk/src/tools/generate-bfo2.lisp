(defun generate-bfo2 (bfo2)
  (with-obo-metadata-uris
    (with-ontology bfo2-ont (:ontology-iri !obo:bfo.owl :version-iri !obo:bfo/dev/bfo.owl :base !obo: :collecting t
					   :ontology-properties (generate-ontology-properties bfo2))
	((as (generate-ontology-annotation-property-defs bfo2))
	 (as (generate-declarations bfo2))
	 (as (generate-label-annotations bfo2))
	 (as (generate-hierarchy bfo2))
	 (as (generate-property-inverses bfo2))
	 (as (generate-reference-annotations bfo2))
	 (as (generate-reference-annotations bfo2))
	 (as (gather-non-reference-annotations bfo2))
	 (as (read-bfo-specific-annotation-properties bfo2))
	 ;(as (parse-annotations bfo2))
	 ;(as (add-annotations bfo2))
	 )
      (write-rdfxml bfo2-ont "bfo:src;ontology;owl-group;bfo.owl"))))

(defun generate-declarations (bfo2)
  (let ((seen (make-hash-table))
	(axs nil))
    (with-bfo-uris bfo2
      (loop for (table type) in
	   '((bfo-class2subclass class) (bfo-2prop2subprop object-property) (bfo-3prop2subprop Object-property))
	   do
	   (maphash (lambda(c sc) 
		      (loop for el in (cons c sc)
			 do
			 (unless (gethash el seen)
			   (push `(declaration (,type ,(eval el))) axs)
			   (setf (gethash el seen) t))))
		    (funcall table bfo2)))
      axs)))

(defun generate-hierarchy (bfo2)
  (let ((axs nil))
    (with-bfo-uris bfo2
      (loop for (table relation) in
	   '((bfo-class2subclass subclassof) (bfo-2prop2subprop subobjectpropertyof) (bfo-3prop2subprop subobjectpropertyof))
	   do
	   (maphash (lambda(super subs) 
		      (loop for sub in subs
			 do (and sub super (push `(,relation ,(eval sub) ,(eval super)) axs))))
		    (funcall table bfo2))))
    axs))     

(defun generate-property-inverses (bfo2)
  (with-bfo-uris bfo2
    (loop with uris = (cdr (bfo-uris bfo2))
       for (name . keys) in (cdr (bfo-terms bfo2))
       for temporal = (find-if (lambda(el) (and (consp el) (eq (car el) :temporal))) keys )
;       do (print-db name keys)
       when (and (consp name) (member :binary keys))
       collect `(inverse-object-properties ,(eval (first name)) ,(eval (second name)))
       when (and (consp name) (member :ternary keys))
	 if (and (assoc (st-term (first name )) uris)
		 (assoc (st-term (second name )) uris))
	 collect `(inverse-object-properties ,(eval (st-term (first name))) ,(eval (st-term (second name))))
	 )))

(defun st-term (name)
  (intern (format nil "~a_ST" (string name))))

(defun at-term (name)
  (intern (format nil "~a_AT" (string name))))

(defun generate-disjoints (bfo2)
  (with-bfo-uris bfo2
    (loop for class in (bfo-terms-with-md-siblings bfo2)
	 for children = (gethash class (bfo-class2subclass bfo2))
	 collect `(disjoint-classes ,@(mapcar 'eval children)))))

(defun parse-annotations (bfo2)
  (with-obo-metadata-uris
    (loop for rawa = (extract-raw-bfo-annotations)
       for table = (make-hash-table :test 'equalp)
       for (annotation-type term text) = rawa
       do
       ;; as|at|a|axiom|domain|range|note|example
       (cond ((equal annotation-type "note")
	      (push (cons !editor-note (format nil "BFO 2 Reference: ~a" (#"replaceAll" (#"replaceAll" text "^\\s+" "") "\\s+$" "")))
		    (gethash (uri-for-reference-doc-term term) table)))
	     ((equal annotation-type "example")
	      (push (cons !example-of-usage  (#"replaceAll" (#"replaceAll" text "^\\s+" "") "\\s+$" ""))
		    (gethash (uri-for-reference-doc-term term) table)))
	     ((member annotation-type '("as" "at" "a") :test 'equalp)
	      (loop for (prop text) in (parse-as text)
		 do 
		 (push (cons prop text)
		       (gethash (uri-for-reference-doc-term term) table))))
	     (t nil))
	 finally (setf (bfo-term2annotation bfo2) table))))


    


	     
  
