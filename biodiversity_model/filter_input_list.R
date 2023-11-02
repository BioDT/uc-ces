filter_strings <- function(input_vector) {
  # Use regular expression to filter strings
  filtered_strings <- input_vector[grep("^[a-z]_", input_vector)]
  return(filtered_strings)
}

input_vector <- names(input_list)
filtered_strings <- filter_strings(input_vector)
print(filtered_strings)

input_list = input_list[filter_strings(names(input_list))]


