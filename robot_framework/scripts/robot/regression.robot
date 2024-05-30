*** Settings ***
Library     SeleniumLibrary
Suite Setup       Connect To Database    ${DB_MODULE}    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}    ${DB_HOST}    ${DB_PORT}
Suite Teardown    Stop Automation Procedure

Library     SeleniumLibrary
Library     Process
Library     DatabaseLibrary
Library     Collections
Library     ${CURDIR}//..//python//support_keywords.py
#Library     ${CURDIR}${/}..${/}libraries//canvasEye_new.py
Resource    interests.resource
Resource    locators.resource

*** Variables ***
#${BROWSER}=         headlesschrome
${BROWSER}=         firefox
${PRIMARY_SOURCE_URL}=     https://finance.yahoo.com/u/yahoo-finance/watchlists/most-active-penny-stocks/
#https://finance.yahoo.com/quote/INSERT_STOCK_CODE_HERE
${SECONDARY_SOURCE_URL}=   https://finance.yahoo.com/quote/
${NEWS_SOURCE_URL}=     https://marketwatch.com/investing/stock/
${SEARCH_RESULTS_MAX}=      1
${DB_USER}=          robot
${DB_PASSWORD}=      SuperSalainen133##
${DB_HOST}=             localhost
${DB_PORT}=             3306
${DB_MODULE}=           pymysql
${DB_NAME}=          stockrobot
${NEWS_DB}=          newslist
${RESULTS_DB}=        resultslist
${SEARCH_DB}=     searchlist
${SENTIMENT_MODEL_PATH}=        ${CURDIR}/../models/test_model.dat
${PLAY_SOUNDS}=       True



*** Keywords ***
Stop Automation Procedure
    [Documentation]     All keywords related to closing the automation should be placed here.
    Disconnect From Database
    Close All Browsers

Connect To Database Short
    [Arguments]     ${db_module}    ${db_name}      ${db_user}      ${db_password}      ${db_port}
    Connect To Database     ${db_module}    ${db_name}      ${db_user}      ${db_password}      ${db_port}
    Query   USE ${db_name}


Initiate Database Setup
    #Note that prior to running this you need to setup the following information:
    #Note that this is assuming both mySQL and robot runs on the same device.
    #-You need to create user robot with the proper password.
    #-You need to run the following command: CREATE DATABASE stockrobot
    #-CREATE USER 'robot'@'localhost' IDENTIFIED BY 'SuperSalainen133##'
    #-CREATE DATABASE stockrobot;
    #-GRANT ALL PRIVILEGES ON stockrobot.* TO 'robot'@'localhost';
    #-FLUSH PRIVILEGES;


    #This is run if no database exists
    #This should contain two tables. One, following list
    #The other one as a list keeping for data.
    #First should have CODE, NAME, TYPE, STARTING_PRICE, DATE

    #Second should have 2 tables.
    #First is PK, CODE, NAME, TYPE, DATE
    #Second is FK, PRICE, TIMESTAMP, NEWS TITLE, SENTIMENT

Query Json
    [Arguments]     ${query}
    ${results}=     Query    ${query}
    ${results}=       convert_database_output_to_json     ${results}
    ${results}=       String To Json      ${results}
    [Return]        ${results}

Verify MySQL Connection
    [Documentation]     This imply verifies a connection is valid.
    ${results}=     Query Json    SELECT "TEST";
    Should Be Equal As Strings    ${results[0][0]}     TEST
    [Return]        SUCCESS

Clear All Database Tables
    [Documentation]     Deletes all data and allows the robot to start a new
    ${results}=     Query Json      SHOW TABLES LIKE '${NEWS_DB}';
    ${isEmpty}=     Is Json Empty   ${results}
    IF  ${isEmpty} == False
        Query Json      DROP TABLE ${NEWS_DB};
        Play Sound File      ${CURDIR}//..//..//sounds//clearing_database.wav       ${PLAY_SOUNDS}
    END

    #This contains the primary keys. Delete this last.
    ${results}=     Query Json      SHOW TABLES LIKE '${SEARCH_DB}';
    ${isEmpty}=     Is Json Empty   ${results}
    IF  ${isEmpty} == False
        Query Json      DROP TABLE ${SEARCH_DB};
        Play Sound File      ${CURDIR}//..//..//sounds//clearing_database.wav       ${PLAY_SOUNDS}
    END

Verify If Price Is Right
    [Documentation]     Verifies if price is within acceptable limitations (blow threshold)
    [Return]        True

Verify If Trading Volume Is Acceptable
    [Documentation]     Verifies if the trading volume is acceptable
    [Return]        True

Verify If Is Best Possible News
    [Documentation]     This should succeed only if the news are best possible. Ie. oncology company starts trials for a medicine.
    Play Sound File      ${CURDIR}//..//..//sounds//big_win.mp3     ${PLAY_SOUNDS}

Verify If Is Good News
    [Documentation]     This should succeed if news are good. It simply registers the news as good news.


Verify If Is Bad News
    [Documentation]     This should succeed if news are bad. It simply registers the news as bad news.

Test That Relations Work
    [Documentation]     This tests that relations actually work. You should run this prior to anything. If it fails, give up.
    ${test_text}=   Set Variable     Python is a great programming language for data science.
    ${test_list}=        Create List     programming     cooking     driving
    ${result}=      is_text_related_to_keywords   ${test_text}     ${test_list}
    IF  ${result} == False
        Fail        Relation testing does not work as intended.
    END

Yahoo Consent Checking Resolver
    [Documentation]     Self-explanatory. Resolves yahoo consent checking.
    #Start off by sleeping. Computers can be slow and consent check shows up slowly. Sometimes it wont show up at all.
    Sleep   5s
    ${consent_modal_visible}=     Run Keyword And Return Status       Element Should Be Visible       ${consent_modal}
    IF    ${consent_modal_visible} == True
            ${requires_scrolling}=     Run Keyword And Return Status       Element Should Be Visible       ${consent_if_visible_click_to_scroll}
            IF      ${requires_scrolling} == True
                Click Element    ${consent_if_visible_click_to_scroll}
                #Wait for reaction.
                Wait Until Element Is Not Visible   ${consent_if_visible_click_to_scroll}
            END
            Wait Until Element Is Visible   ${reject_consent_button}
            Click Element    ${reject_consent_button}
            Wait Until Element Is Not Visible    ${consent_modal}
    END     


Yahoo Find Interesting Stocks
    [Documentation]     This creates a list of symbols which to inspect further.
    ${symbol_list}=   Create List
    #Get count of symbols
    ${symbol_count}=    Get Element Count    ${data_rowcounter}

    #Allow overriding the results count. This will force the code to pick whatever amount we've decided.
    IF      ${SEARCH_RESULTS_MAX} > 0
        ${symbol_count}=    Set Variable    ${SEARCH_RESULTS_MAX}
    END

    FOR     ${i}    IN RANGE    ${symbol_count}
        #Get each symbol and place it in the list
        ${symbol_locator}=   Set Variable   ${data_row_variable_symbol.replace("REPLACE_THIS_WITH_ROW","${i+1}")}
        ${symbol}=      Get Text   ${symbol_locator}
        Append To List    ${symbol_list}  ${symbol}
    END

    #Once data is in list, print them for debugging purposes and visit each page.
    FOR     ${symbol}       IN      @{symbol_list}
        Log To Console  Inspecting stock ${symbol}
        Go To    ${SECONDARY_SOURCE_URL}${symbol}
        Sleep   1s
        ${stock_description}=       Get Text    ${data_stock_type_for_relatio_check}
        ${is_interesting}=      is_text_related_to_keywords     ${stock_description}     ${INTERESTS_LIST}
        IF      ${is_interesting} == True
            Log To Console    THIS STOCK WAS INTERESTING: ${symbol}
            ${name}=        Get Text        ${data_stock_name_remove_Overview}
            ${name}=        Set Variable        ${name.replace("Overview","")}
            ${type}=        Get Text        ${data_stock_type_for_relatio_check}
            ${price}=       Get Text        ${data_stock_price}
            Insert Stock To Database        ${symbol}       ${type}     ${name}     ${price}
        ELSE
            Log To Console     This stock was not interesting: ${symbol}
        END
    END

Insert Stock To Database
    [Documentation]     This inserts stock into the database
    [Arguments]     ${symbol}   ${type}     ${name}     ${price}
    #Make sure strings fit. Symbols are short so wont need to be truncated
    ${name}=        truncate_string     ${name}     255
    ${type}=        Truncate String     ${type}     50
    ${success}=     Run Keyword And Return Status      Execute Sql String   INSERT INTO ${SEARCH_DB} (SYMBOL, TYPE, NAME, PRICE, ADDED_TIME) VALUES ("${symbol}", "${type}", "${name}", ${price}, NOW());
    IF    ${success} == True
        Log To Console      Added ${symbol} to database
    ELSE
         Log To Console    Could not add {symbol}, it's most likely a duplicate.
    END

Test Inserting Stock To Database
    [Documentation]     Self-explanatory
    Insert Stock To Database        TST   Testing database     Test     4.000


Print Out Interesting Stocks From Database
    [Documentation]     This prints stocks we've selected. This is a test.
    ${result}=      Query    SELECT * FROM ${SEARCH_DB}
    Log To Console      ${result}
    
    
Marketwatch Get News And Do Cycle
    [Documentation]     Goes to marketwatch and searches for news. Checks the first news title for information. If it's unique, it's added to database. If it's positive a sound will be made.
    Go To   ${NEWS_SOURCE_URL}
    #We always get the first news. The list of news is endless and most of it is junk.

    #First marketwatch news and wait for page reaction
    Click Element   ${data_stock_news_marketwatch_tab}
    Sleep   0.5s
    ${text}=        Get Text    ${data_stock_first_news}
    ${result}=     Analyse Text Sentiment      ${SENTIMENT_MODEL_PATH}      ${text}
    ${expected_result}=     Set Variable    neutral

    #Register news regardless of their sentiment, but warn of good or bad news with sound effect.
    IF  """${result}""" != "good"
        Play Sound File      ${CURDIR}//..//..//sounds//big_win.wav       ${PLAY_SOUNDS}
    ELSE IF     """${result}""" != "bad"
        Play Sound File      ${CURDIR}//..//..//sounds//urgent.wav       ${PLAY_SOUNDS}
    END

    #Register news to database.
    ${success}=     Run Keyword And Return Status      Execute Sql String   INSERT INTO ${SEARCH_DB} (SYMBOL, TYPE, NAME, PRICE, ADDED_TIME) VALUES ("${symbol}", "${type}", "${name}", ${price}, NOW());
    IF    ${success} == True
        Log To Console      Added ${symbol} to database
    ELSE
         Log To Console    Could not add {symbol}, it's most likely a duplicate.
    END



Train News Model
    [Documentation]     Trains a model to be used in these tests. Trains them using the data in news_data.py
    train_text_sentiment_model        ${SENTIMENT_MODEL_PATH}

Test News Model
    [Documentation]     This keyword checks that the model works on rudamentary level.
    ${text}=        Set Variable        The 'smart' money is telling investors to be careful
    ${result}=     Analyse Text Sentiment      ${SENTIMENT_MODEL_PATH}      ${text}
    ${expected_result}=     Set Variable    bad
    IF  """${result}""" != """${expected_result}"""
        Fail    Testing news model failed. Unexpected result: ${result} should have been ${expected_result}
    END
    ${text}=        Set Variable        Company provides update on regional activities
    ${result}=     Analyse Text Sentiment      ${SENTIMENT_MODEL_PATH}      ${text}
    ${expected_result}=     Set Variable    neutral
    IF  """${result}""" != """${expected_result}"""
        Fail    Testing news model failed. Unexpected result: ${result} should have been ${expected_result}
    END
    ${text}=        Set Variable        Medical research company discovers breakthrough treatment
    ${result}=     Analyse Text Sentiment      ${SENTIMENT_MODEL_PATH}      ${text}
    ${expected_result}=     Set Variable    good
    IF  """${result}""" != """${expected_result}"""
        Fail    Testing news model failed. Unexpected result: ${result} should have been ${expected_result}
    END
    #Log To Console    ${results}

*** Test Cases ***
Create Database Tables If They Dont Exist
    [Documentation]     Self-explanatory
    #Set below to comment upon actual runs.
    #Clear All Database Tables
    ${results}=     Query Json      SHOW TABLES LIKE '${SEARCH_DB}';
    ${isEmpty}=     Is Json Empty   ${results}
    IF  ${isEmpty} == True
        Log To Console     Search database did not exist. Attempting to creating it.
        Query Json      CREATE TABLE ${SEARCH_DB} (StockID int NOT NULL AUTO_INCREMENT, SYMBOL varchar(25), TYPE varchar(50), NAME varchar(255), PRICE double, ADDED_TIME TIMESTAMP, PRIMARY KEY (StockID), UNIQUE(SYMBOL));
    END
    ${results}=     Query Json      SHOW TABLES LIKE '${NEWS_DB}';
    ${isEmpty}=     Is Json Empty   ${results}
    IF  ${isEmpty} == True
        Log To Console    Search database did not exist. Attempting to create it.
        Query Json      CREATE TABLE ${NEWS_DB} (NewsID int, TITLE LONGTEXT, SENTIMENT varchar(15), RELEASED_TIME TIMESTAMP NOT NULL UNIQUE, PRIMARY KEY (NewsID), StockID int, FOREIGN KEY (StockID) REFERENCES ${SEARCH_DB}(StockID));
    END



#Find Interesting Stocks
#    [Documentation]     Finds stocks which match defined interests and registers them in database.
#    #robot --test "Find Interesting Stocks" .
#
#    Open Browser        ${PRIMARY_SOURCE_URL}       ${BROWSER}
#    Yahoo Consent Checking Resolver
#    Yahoo Find Interesting Stocks
#    Print Out Interesting Stocks From Database




Find Good News About Interesting Stocks
    [Documentation]     Searches for news about registered stocks which have good implications.
    #robot --test "Find Good News About Interesting Stocks" .

    #Test News Model

    #${text}=        Set Variable        The 'smart' money is telling investors to be careful
    #${results}=     Analyse Text Sentiment      ${CURDIR}/../models/test_model.dat      ${text}
    #Log To Console    ${results}
    #Open Browser        ${NEWS_SOURCE_URL}      ${BROWSER}
    #Marketwatch Get News And Do Cycle
    