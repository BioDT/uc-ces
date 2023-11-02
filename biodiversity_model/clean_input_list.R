input_list = readRDS(file.path(getwd(), "ODMAP_template_list.RDS"))
odmap_dict <- read_csv("odmap_dict.csv")

input_list_orig = input_list
keep_elements = c()

for (element in names(input_list_orig)) {

  input_list <- input_list[!names(input_list) %in% element]
  
  result <- tryCatch({
    
    result = render(
      input = file.path(getwd(), "ODMAP_generate.Rmd"),
      output_format = "word_document",
      output_file = file.path(getwd(), "sdm_odmap.docx"),
      params = list(study_title = paste(input_list$o_authorship_1), authors = paste(input_list$first_name, input_list$last_name, collapse = ", "))
    )
    
  }, error = function(e) {
    
   message(paste0("we need ", element))
    return(NULL)
  })
  
  if (is.null(result)) {
    input_list = append(input_list, input_list_orig[element])
  }

}

saveRDS(input_list, "ODMAP_template_list.RDS")
