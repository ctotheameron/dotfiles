; extends

; highlight markdown`...` tagged template contents as markdown
(call_expression
  function: (identifier) @_tag
  (#eq? @_tag "markdown")
  arguments: (template_string
    (string_fragment) @injection.content
    (#set! injection.language "markdown")
    (#set! injection.combined)))
