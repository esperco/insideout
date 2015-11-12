let main () =
  print_string (
    Example.preview
      ~name: "User"
      ~num: 1
      ~html_snippet: "<b>bold</b> normal <i>italics</i>"
      ()
  )

let () = main ()
