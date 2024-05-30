*** Variables ***

#YAHOO MARKET WATCHLIST VARIABLES BEGIN HERE

#Consent modal stuff
${consent_modal}=                           //*[contains(@class,"consent-overlay")]
${consent_if_visible_click_to_scroll}=      //*[@id="scroll-down-btn"]
${reject_consent_button}=                   //button[contains(@class,"reject-all")]
#Rowcounter
${data_rowcounter}=                         //*[contains(@class,"cwl-symbols")]//..//tbody/tr
${data_row_variable_symbol}=                //*[contains(@class, "cwl-symbols")]/..//tbody/tr[REPLACE_THIS_WITH_ROW]//td[1]//a
#${data_row_variable_name}=                  //*[contains(@class, "cwl-symbols")]/..//tbody/tr[REPLACE_THIS_WITH_ROW]//td[2]
#${data_row_variable_price}=                 //*[contains(@class, "cwl-symbols")]/..//tbody/tr[REPLACE_THIS_WITH_ROW]//td[3]
#${data_row_variable_volume}=                //*[contains(@class, "cwl-symbols")]/..//tbody/tr[REPLACE_THIS_WITH_ROW]//td[7]

#Secondary source variables for figuring out details
${data_stock_type_for_relatio_check}=                         //*[contains(@class,"acc-header")]//*[contains(@class,"title")]//span[2]
${data_stock_price}=        //*[@data-testid="quote-price"]//*[contains(@class,"livePrice")]//span
${data_stock_name_remove_Overview}=         //*[contains(@class,"acc-header")]//*[contains(@class,"title")]//span[1]

#News source. First news
${data_stock_news_marketwatch_tab}=     //*[contains(@data-track-code,"News_MarketWatch")]
${data_stock_news_dow_jones_tab}=       //*[contains(@data-track-code,"News_Dow")]
${data_stock_first_news}=       (//html//*[contains(@class,"article__content")])[1]//h3
${data_stock_first_timestamp}=      (//html//*[contains(@class,"article__content")])[1]//*[contains(@class,"article__timestamp")]


#YAHOO MARKET WATCHLIST VARIABLES END HERE
