targets::tar_test("tar_duck_rmd works", {

  fs::dir_create("sql")
  firms_lines <- "
---
title: 'SQL Notebook'
output:
  html_notebook:
    toc: yes
    toc_float:
      collapsed: no
    number_sections: no
    code_folding: hide
always_allow_html: true
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(connection = 'db')
```

```{sql}
CREATE OR REPLACE TABLE firms (
  code INT,
  name VARCHAR(10)
);

INSERT INTO firms (code, name)
VALUES
  (1, 'BMW'),
  (2, 'DAIMLER'),
  (3, 'FORD'),
  (4, 'NISSAN'),
  (5, 'RENAULT')
;
```
  "
  writeLines(firms_lines, "sql/firms.Rmd")

  revenue_lines <- "
---
title: 'SQL Notebook'
output:
  html_notebook:
    toc: yes
    toc_float:
      collapsed: no
    number_sections: no
    code_folding: hide
always_allow_html: true
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(connection = 'db')
```

```{sql}
CREATE OR REPLACE TABLE revenue (
  code INT,
  year INT,
  value INT
);

INSERT INTO revenue (code, year, value)
VALUES
  (1, 2021, 2),
  (2, 2021, 6),
  (3, 2021, 4),
  (4, 2021, 8),
  (5, 2021, 9),
  (1, 2022, 1),
  (2, 2022, 2),
  (3, 2022, 3),
  (4, 2022, 4),
  (5, 2022, 5)
;
```
  "
  writeLines(revenue_lines, "sql/revenue.Rmd")

  totals_lines <- "
---
title: 'SQL Notebook'
output:
  html_notebook:
    toc: yes
    toc_float:
      collapsed: no
    number_sections: no
    code_folding: hide
always_allow_html: true
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(connection = 'db')
```

```{r load-targets}
revenue
firms
```

```{sql}
CREATE OR REPLACE TABLE totals AS
SELECT firms.name AS name, SUM(revenue.value) AS value
FROM revenue
LEFT JOIN firms
ON revenue.code = firms.code
GROUP BY firms.name
;
```
  "
  writeLines(totals_lines, "sql/totals.Rmd")

  targets::tar_script({

    list(
      flowme::tar_duck_rmd("sql/firms.Rmd"),
      flowme::tar_duck_rmd("sql/revenue.Rmd"),
      flowme::tar_duck_rmd("sql/totals.Rmd"),

      NULL
    )
  })

  # test the dependencies are correctly induced
  testthat::expect_setequal(
    object = targets::tar_network()$edges |>
      dplyr::mutate(fromto = paste0(from, "->", to)) |>
      dplyr::pull(fromto),
    expected = c(
      "firms->totals",
      "revenue->totals"
    )
  )

  testthat::expect_no_error(targets::tar_make())

  # after running tar_make, there should one duckdb file per target
  testthat::expect_true(file.exists("./duckdb/firms"))
  testthat::expect_true(file.exists("./duckdb/revenue"))
  testthat::expect_true(file.exists("./duckdb/totals"))

  duck_file <- "./duckdb/firms"
  duck_con <- DBI::dbConnect(duckdb::duckdb(duck_file, read_only = TRUE))
  duck_data <- DBI::dbGetQuery(duck_con, "SELECT * FROM firms;")
  DBI::dbDisconnect(duck_con, shutdown = TRUE)
  #testthat::expect_known_hash(duck_data, "a3342f4eb3")
  testthat::expect_equal(duck_data, structure(
    list(
      code = 1:5,
      name = c("BMW", "DAIMLER", "FORD", "NISSAN", "RENAULT")
    ),
    class = "data.frame",
    row.names = c(NA, -5L)
  ))

  duck_file <- "./duckdb/revenue"
  duck_con <- DBI::dbConnect(duckdb::duckdb(duck_file, read_only = TRUE))
  duck_data <- DBI::dbGetQuery(duck_con, "SELECT * FROM revenue;")
  DBI::dbDisconnect(duck_con, shutdown = TRUE)
  #testthat::expect_known_hash(duck_data, "564be8150b")
  testthat::expect_equal(duck_data, structure(
    list(
      code = c(1L, 2L, 3L, 4L, 5L, 1L, 2L, 3L, 4L, 5L),
      year = c(2021L, 2021L, 2021L, 2021L, 2021L, 2022L, 2022L,
               2022L, 2022L, 2022L),
      value = c(2L, 6L, 4L, 8L, 9L, 1L, 2L, 3L, 4L, 5L)
    ),
    class = "data.frame",
    row.names = c(NA, -10L)
  ))

  duck_file <- "./duckdb/totals"
  duck_con <- DBI::dbConnect(duckdb::duckdb(duck_file, read_only = TRUE))
  duck_data <- DBI::dbGetQuery(duck_con, "SELECT * FROM totals;")
  DBI::dbDisconnect(duck_con, shutdown = TRUE)
  #testthat::expect_known_hash(duck_data, "715c4129e8")
  testthat::expect_equal(duck_data, structure(
    list(
      name = c("BMW", "DAIMLER", "FORD", "NISSAN", "RENAULT"),
      value = c(3, 8, 7, 12, 14)
    ),
    class = "data.frame",
    row.names = c(NA, -5L)
  ))

})

