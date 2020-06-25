library(ymlthis)
yml_empty() %>%
  yml_author(.yml, name = "Yihui Xie", affiliation = "INTA", email = "edwardsmolina@gmail.com") %>% 
  yml_author("Yihui Xie") %>%
  yml_date("02-02-2002") %>%
  yml_title("R Markdown: An Introduction") %>%
  yml_subtitle("Introducing ymlthis") %>%
  yml_abstract("This paper will discuss a very important topic") %>%
  yml_keywords(c("r", "reproducible research")) %>%
  yml_subject("R Markdown") %>%
  yml_description("An R Markdown reader") %>%
  yml_category("r") %>%
  yml_lang("en-US")

post_listing <- distill_listing(
  slugs = c(
    "2016-11-08-sharpe-ratio",
    "2017-11-09-visualizing-asset-returns",
    "2017-09-13-asset-volatility"
  )
)

yml() %>%
  yml_title("Gallery of featured posts") %>%
  yml_distill_opts(listing = post_listing)

install.packages("distill")
