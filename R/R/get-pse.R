#' Returns pricing data for a specified stock
#'
#' @param sym A string indicating the symbol of the stock in the PSE. For more
#'   details, you can refer to this [link](https://www.pesobility.com/stock).
#' @param s_date A string indicating a date in the YYYY-mm-dd format, serves
#'   as the start date of the period to get stock data
#' @param e_date A string indicating a date in the YYYY-mm-dd format, serves
#'   as the end date of the period to get stock data
#'
#' @return A tibble, with the following columns:
#' * symbol: The ticker symbol of the stock
#' * dt: The date for the closing price of the stock
#' * name: The name of the company represented by the stock ticker
#' * currency: The currency of the closing price of the stock
#' * close: The closing price of the stock at the given date, dt
#' * percent_change: The percentage day change of the stock
#' * volume: The total value of shares traded of the stock at dt
#' @md
#'
#' @importFrom lubridate parse_date_time
#' @importFrom assertthat assert_that
#' @importFrom dplyr tibble mutate filter
#' @importFrom tidyr unnest
#' @importFrom purrr map2
#' @importFrom httr GET content
#' @importFrom magrittr `%>%`
#' @export
get_pse_data <- function(sym, s_date, e_date) {

  assert_that(is.character(sym),
              msg = "`sym` must be character")

  assert_that(length(sym) == 1,
              msg = "`sym` must be length 1")

  assert_that(!is.na(parse_date_time(s_date, orders = "ymd")),
              msg = "s_date is not in YYYY-mm-dd format")

  assert_that(!is.na(parse_date_time(e_date, orders = "ymd")),
              msg = "e_date is not in YYYY-mm-dd format")

  # TODO Check /data if the symbol exists as a file
  # TODO Check /data if the symbol exists for the time frame
  # TODO Cut relevant rows from dataset
  # TODO Change s_date and e_date as applicable

  res <- tibble(symbol = sym,
                dt = seq(as.Date(s_date), as.Date(e_date), by = "days")) %>%
         mutate(data = map2(symbol, dt, get_pse_data_by_date)) %>%
         unnest(data) %>%
         filter(!is.na(name))
  return(res)
}


# Utility function for getting single ticker data for symbol, date
get_pse_data_by_date <- function(symbol, date){
  if (paste0("http://1.phisix-api.appspot.com/stocks/",
                symbol, ".", date, ".json") %>%
    GET() %>%
    content(type="application/json") %>%
    is.null()) {

    req <- paste0("http://phisix-api.appspot.com/stocks/",
                  symbol, ".", date, ".json") %>%
      GET() %>%
      content(type="application/json")

  } else {
    req <- paste0("http://1.phisix-api.appspot.com/stocks/",
                  symbol, ".", date, ".json") %>%
      GET() %>%
      content(type="application/json")
  }

  if (is.null(req)) {
    return(as.data.frame(list(name = NA_character_,
                              currency = NA_character_,
                              close = NA_real_,
                              percent_change = NA_real_,
                              volume = NA_real_)))
  } else {
    return(as.data.frame(list(name = req$stock[[1]]$name,
                              currency = req$stock[[1]]$price$currency,
                              close = req$stock[[1]]$price$amount,
                              percent_change = ifelse(
                                is.null(req$stock[[1]]$percent_change),
                                NA_real_,
                                req$stock[[1]]$percent_change),
                              volume = req$stock[[1]]$volume)))
  }
}
