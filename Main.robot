*** Settings ***
Library    Autosphere.Browser.Selenium


*** Keywords ***
FP PS HK Wastage Bot 1
    
    Connect
    Query  UPDATE `foodpanda`.`fp_wastage_termination_handle` SET `error_flag` = 0 WHERE `bot_name` = 'Hongkong';
    Run Keyword and return status  delete_old_files   C:\\Error_Screenshots
    Start Chrome Browser
    Go To  ${GO_TO_URL_QUEUE}
    # Go To  https://deliveryhero.lightning.force.com/lightning/o/Case/list?filterName=00B1r00000C1VwPEAV
    ${login_check}  Check If Already Logged In
    IF  '${login_check}'=='True'
        Log  Already Logged In
		sleep  1s
		#Click Element When Visible   (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
		sleep  1s
    ELSE
        Select Login with SSO
        Login on Sales Force
        ${lg_status}=  Check If OTP screen visible
        IF  '${lg_status}'=='True'
            Send Email OTP 
        END
         
        # Enter Security Questions
    END
    Set Selenium Timeout    20 seconds    # Increase the timeout to 20 seconds
    Select Cases and Region
	Refresh Page And Wait For List View
    # Run Keyword And Return Status  Ticket dump into Database
	Connect
	#changes
	${Curtime}  Get Current Date  exclude_millis=True
	${time_plus15}=      Add Time To Date      ${Curtime}      ${Task_Time} minutes  exclude_millis=True
	FOR    ${i}    IN RANGE    99
        Log  Queue Name: ${region_name}
	    ${cur_time}  Get Current Date  exclude_millis=True
	    ${time_check}  Subtract Date From Date  ${time_plus15}  ${cur_time}
		${error_flag}=  Query Error Flag Count
        IF  ${error_flag} == 1
            Exit For Loop
        END
        IF    ${time_check} > 1
            ${Overall_status}  ${Error_Message}=  Run keyword and ignore error  Search List And Process Ticket    ${i}
            IF  "${Overall_status}" == "False" or '${Overall_status}' == 'FAIL'
                #All Teardown Logic
                # Notifying the issue in Database
                ${failure_time} =  Get Current Date  result_format=datetime
                ${sanitized_input}    Validate and Sanitize Input    ${Error_Message}
                ${Job_ID}=   Evaluate   os.environ.get("BUILD_NUMBER", None)
                Query  INSERT IGNORE INTO foodpanda.fp_wastage_exceptions (`date_time`,`job_id`, `bot_name`,`error_message`) VALUES ('${failure_time}','${Job_ID}', '${PandaBotName}', '${sanitized_input}')
                Query  INSERT IGNORE INTO foodpanda.fp_wastage_alerts (`date_time`, `bot_name`,`error_message`) VALUES ('${failure_time}', '${PandaBotName}', '${sanitized_input}')
                ${Screenshot_path}=  Capture Error Screenshots
                # Go to home URL 
                # Go To  https://deliveryhero.lightning.force.com/lightning/o/Case/list?filterName=00B1r00000C1VwPEAV
                # Select Region Queue after Goto
                Go To  ${GO_TO_URL_QUEUE}
                Check Database Entries  ${Error_Message}  ${Screenshot_path}
            END
        ELSE
            Exit For Loop
        END
		#Run Keyword If  ${time_check} > 1  Search List And Process Ticket  ELSE  Exit For Loop
    END

*** Keywords ***
Teardown Alerts
    ${Screenshot_path}=  Set Variable  ${EMPTY}
    IF    '${TEST_STATUS}' == 'FAIL'
        ${Screenshot_path}=  Capture Error Screenshots
    END
    Close All Browsers    
    IF    '${TEST_STATUS}' == 'FAIL'
        ${failure_time} =  Get Current Date  result_format=datetime
        ${status}=  Run Keyword and Return Status  Connect
        ${sanitized_input}    Validate and Sanitize Input    ${TEST MESSAGE}

        IF  '${status}' == 'False'
            Send Email    [Alert] ${PandaBotName} Failed on connecting with Database
            ...  This is an Alert notification email, the ${PandaBotName} is failing on database connection, the last encountered error is:\n ${Test Message} \nKindly verify the highlighted issue.\nThanks
            ...  delivery.alerts@autosphere.ai
            Log  Sending Email
        ELSE
            Query  INSERT IGNORE INTO foodpanda.fp_wastage_alerts (`date_time`, `bot_name`,`error_message`) VALUES ('${failure_time}', '${PandaBotName}', '${sanitized_input}')
            ${Job_ID}=   Evaluate   os.environ.get("BUILD_NUMBER", None)
            Query  INSERT IGNORE INTO foodpanda.fp_wastage_exceptions (`date_time`,`job_id`, `bot_name`,`error_message`) VALUES ('${failure_time}','${Job_ID}', '${PandaBotName}', '${sanitized_input}')
            Query  UPDATE foodpanda.fp_wastage_termination_handle SET `error_flag` = 1 WHERE `bot_name` = 'Hongkong';
            Check Database Entries   ${TEST MESSAGE}  ${Screenshot_path}
        END
        
    END
    Delete Rows Within two Hour  ${PandaBotName}
Send Email Alert
    [Arguments]  ${Subject}  ${body}  ${to}
    # Authorize SMTP connection
    Authorize SMTP    ${sl_user_name}    ${APP_PASSWORD}  smtp.gmail.com    587  
    # Send the email
    Send Message    ${sl_user_name}  ${to}  ${Subject}  ${body}
Scroll Element By Xpath
    [Arguments]  ${xpath}
    Execute Javascript    var xpathResult = document.evaluate(`${xpath}`, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null); var element = xpathResult.singleNodeValue; element.scrollIntoView({behavior: 'auto', block: 'center'});

Ticket dump into Database
    ${counter}=  Set Variable  1
    FOR    ${iter}    IN RANGE    20
        ${scrolling_down}  Get WebElements  //span[@class="countSortedByFilteredBy" and contains(text(),'+')]
        ${len_scroll}  Get Length    ${scrolling_down}

        IF  ${len_scroll} > 0
            
            @{Ticket_elements}  Get WebElements   //th//a[@data-refid="recordId"]
            FOR    ${index}    ${element}    IN ENUMERATE    @{Ticket_elements}
                 
                Run keyword and return status  Scroll Element By Xpath     (//th//a[@data-refid="recordId"])[${counter}]
                ${counter}=  Evaluate    ${counter} + 1
            END
            
            Sleep  2s
        END
    END 
    Run keyword and return status  Scroll Element By Xpath     (//th//a[@data-refid="recordId"])[1]
    @{Ticket_elements}  Get WebElements   //th//a[@data-refid="recordId"]
     FOR    ${item}    IN     @{Ticket_elements}
        ${current_time}=    Get Current Date    result_format=%Y-%m-%d-%H-%M-%S
        ${Ticket_id_db}   Get Text    ${item} 
        Query  INSERT IGNORE INTO foodpanda.fp_wastage_salesforce_tickets (`ticket`, `ticket_arrival_time`,`panda_bot`,`region`) VALUES ('${Ticket_id_db}', '${current_time}', '${PandaBotName}','${region}')
    END
*** Keywords ***
Capture Error Screenshots 
    Run keyword and Return status   Set Screenshot Directory  C:\\Error_Screenshots
    ${current_time}=    Get Current Date    result_format=%Y-%m-%d-%H-%M-%S
    Run keyword and Return status   Capture Page Screenshot  ${current_time}.png
    [Return]  C:\\Error_Screenshots\\${current_time}.png
Check Database Entries
    [Arguments]   ${error_message}  ${Screenshot_path}
    ${current_time}=    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    ${is_issue_found}=    Check Database Entries Within Hour    ${current_time}    ${PandaBotName}
    IF  ${is_issue_found}
        
        # As there are more entries than count, Now going to send email to the stakeholders about the issue
        Send Email    [Alert] The ${PandaBotName} Failed on multiple executions
        ...  This is an Alert notification email, the ${PandaBotName} is failing on multiple executions, the last encountered error is:\n ${error_message} \nKindly verify the highlighted issue.\nThanks
        ...  delivery.alerts@autosphere.ai  ${Screenshot_path}
        
        Delete Rows With Bot In Alerts  ${PandaBotName}
        

    ELSE
        # Here We are going to Query all the rows present for that bot_name within an hour
        # If they are less than the count value then Delete the Rows, otherwise do nothing
        ${count}=    Query Rows Count Within Hour    ${current_time}    ${PandaBotName}
        Log  Rows with bot are ${count}
       
    END
    
    #Disconnect From Database
Query Error Flag Count
    ${sql}=    Catenate    SEPARATOR=    SELECT error_flag FROM foodpanda.fp_wastage_termination_handle WHERE bot_name = 'Hongkong';
    @{rows}=    Query    ${sql}    as_table=False
    ${count}=    Set Variable    ${rows[0][0]}
    [Return]    ${count}
*** Keywords ***
Query Rows Count Within Hour
    [Arguments]    ${current_time}    ${bot_name}
    ${sql}=    Catenate    SEPARATOR=    SELECT COUNT(*) FROM fp_wastage_alerts WHERE date_time >= DATE_SUB('${current_time}', INTERVAL 1 HOUR) AND date_time <= '${current_time}' AND bot_name = '${bot_name}'
    @{rows}=    Query    ${sql}    as_table=False
    ${count}=    Set Variable    ${rows[0][0]}
    [Return]    ${count}

Delete Rows With Bot In Alerts
    [Arguments]    ${bot_name}

    ${sql}=    Catenate    SEPARATOR=    DELETE FROM foodpanda.fp_wastage_alerts where bot_name = '${bot_name}';
    Query    ${sql}
*** Keywords ***
Delete Rows Within two Hour
    [Arguments]    ${bot_name}

    ${sql}=    Catenate    SEPARATOR=    Delete FROM fp_wastage_alerts WHERE date_time <= NOW() - INTERVAL 1 DAY AND bot_name = '${bot_name}';
    Query    ${sql}

*** Keywords ***
Check Database Entries Within Hour
    [Arguments]    ${current_time}    ${bot_name}
    #Sleep  5s
    ${sql}=    Catenate    SEPARATOR=    SELECT COUNT(*) FROM fp_wastage_alerts WHERE date_time >= DATE_SUB('${current_time}', INTERVAL 1 HOUR) AND date_time <= '${current_time}' AND bot_name = '${bot_name}'
    @{res}=    Query    ${sql}  as_table=False  
    ${count}=    Set Variable    ${res[0][0]}
    Log    Number of entries within the last hour for ${bot_name}: ${count}
    ${is_issue_found}=    Evaluate    int(${count}) > ${alert_failure_count}
    [Return]    ${is_issue_found}
Validate and Sanitize Input
    [Arguments]    ${input}
    ${sanitized_input}=  Replace String    ${input}    '    ${EMPTY}
    ${sanitized_input}=  Replace String    ${sanitized_input}    "    ${EMPTY}
  
    [Return]    ${sanitized_input}



Search Ticket if avaiable or not
    Wait Until Keyword Succeeds    3X    3s    Get Text  //div[@class="slds-scrollable_y"]//tbody/tr[1]/th/span/div//div/a/slot/span
Search List And Process Ticket
    [Arguments]  ${iteration}
	Run Keyword And Return Status  Wait Until Page Contains Element  //div[@class="slds-scrollable_y"]//tbody/tr[1]/th/span/div//div/a/slot/span   60
    ${ticket_available}   Run Keyword And Return Status   Search Ticket if avaiable or not 

	
    IF  '${ticket_available}'=='True'  
        Process Ticket  ${iteration} 
        
    ELSE
        Go To  ${GO_TO_URL_QUEUE}   
        # Go To  https://deliveryhero.lightning.force.com/lightning/o/Case/list?filterName=00B1r00000C1VwPEAV
        # Select Region Queue after Goto

    END

Connect
    Connect To Database
    ...    pymysql
    ...    foodpanda
    ...    foodpanda
    ...    foodpanda1
    ...    10.1.4.41
    ...    3306

Open salesforce portal
    Open Available Browser  https://deliveryhero.lightning.force.com/lightning/o/Case/list?filterName=00B1r00000C1VwPEAV  chrome  maximized=True

Check If Already Logged In
    ${cases_status}  Run Keyword And Return Status  Wait Until Element Is Enabled  //a/span[contains(text(),"Cases")]  10
    IF  '${cases_status}'=='True'
        return from keyword  True
    ELSE
        return from keyword  False
    END
Check If OTP screen visible
    ${cases_status}  Run Keyword and return status  Wait Until Page Contains Element  //h2[normalize-space()='Get a verification email']  10

    IF  '${cases_status}'=='True'
        return from keyword  True
    ELSE
        return from keyword  False
    END
Select Login with SSO
    Does Page Contain Element    xpath=(//span)[4]
    Click Element When Visible    xpath=(//span)[4]

Login on Sales Force

    
    Wait Until Page Contains Element  //input[@name="identifier"]  50
    #Sleep   1000
    Click Element When Visible    //label[@data-se-for-name="rememberMe"]
    Input Text    //input[@name="identifier"]    ${sl_user_name}
	Wait Until Page Contains Element  //input[@value="Next"]  50
	Click Element  //input[@value="Next"]
	Wait Until Page Contains Element  //input[contains(@class,'password')]  50
    Input Text    //input[contains(@class,'password')]    ${sl_password}
    Click Element When Visible    //input[@value="Verify"]


Mark Previous Emails as Read
    Authorize IMAP    ${sl_user_name}   ${APP_PASSWORD}  imap.gmail.com  993
    Mark As Read  SUBJECT "One-time verification code"
    Delete Messages  SUBJECT "One-time verification code"
Read Emails with Subject
    Authorize IMAP    ${sl_user_name}   ${APP_PASSWORD}  imap.gmail.com  993
    @{emails}  List Messages  SUBJECT "One-time verification code"
    
    FOR  ${email}  IN  @{EMAILS}
        Log  ${email}[Subject]
        Log  ${email}[Body]
        ${email_content} =   Set Variable  ${email}[Body]
      
        ${matches}  Get Regexp Matches  ${email_content}  \\b\\d{6}\\b
        Log  6-digit code: ${matches[0]}
        ${otp_code}=  Set Variable  ${matches[0]}
        Set global variable  ${otp_code}
        #Log  OTP Code: ${otp_code_match}
       
    END
    Mark As Read  SUBJECT "One-time verification code"
    ${len_emails}  Get Length  ${emails}
    IF  ${len_emails} > 0
        Delete Messages  SUBJECT "One-time verification code"
        
    ELSE
        Fail  No OTP Email Has been Found
    END
Send Email OTP
    ${status}=  Run Keyword and return status  Wait Until Page Contains Element  //h2[normalize-space()='Get a verification email']  10
    IF  "${status}" == "False"
        ${visible}=  Is Element Visible  //div[@data-se="okta_email"]
        IF  "${visible}" == "True"
            Click Element  //div[@data-se="okta_email"]  enter
        END
    END

    Wait Until Page Contains Element  //input[@value='Send me an email']  10
    Mark Previous Emails as Read
    Sleep  2s
    Click Element When Visible  //input[@value='Send me an email']  enter
    Wait until keyword succeeds  60  2s  Read Emails with Subject
    log  ${otp_code}
    Input Text When Element Is Visible  //input[@name="credentials.passcode"]  ${otp_code}
    Click Element When Visible  //input[@value='Verify']
    
    
Enter Security Questions
	${status}=  Run Keyword and return status  Wait Until Page Contains Element  //h2[contains(text(),'Security Question')]  50
    IF  "${status}" == "False"
        ${visible}=  Is Element Visible  //div[@data-se="security_question"]
        IF  "${visible}" == "True"
            Click Element  //div[@data-se="security_question"]  enter
            Wait Until Page Contains Element  //h2[contains(text(),'Security Question')]  50
        END
    

    END

    ${security_question_exist} =   Get text  xpath=//h2[contains(text(),'Security Question')]
    IF  '${security_question_exist}'=='Verify with your Security Question'
		Wait Until Page Contains Element  //*[contains(text(),'Security Question')]/../div/div/div/label  50
        ${security_question_text} =   Get text  xpath= //*[contains(text(),'Security Question')]/../div/div/div/label
        ${panda_question}=  Evaluate   'What is the name of your first stuffed animal?' in '${security_question_text}'
		${panda_question2}=  Evaluate   'What is the toy/stuffed animal you liked the most as a kid?' in '${security_question_text}'
        IF  '${panda_question}'=='True'
            Input Text    //input[contains(@class,'password')]    panda
            Click Element When Visible    //input[@value="Verify"]
            sleep  5s

        ELSE IF  '${panda_question2}'=='True'
			Input Text    //input[contains(@class,'password')]    panda
            Click Element When Visible     //input[@value="Verify"]
            sleep  5s
            log to console  question is different

        END
    ELSE
        log to console  No question found
    END

Select Cases and Region
    
    # Wait Until Element Is Visible    //*[@id="brandBand_1"]/div/div/div/div/div[1]/div[1]/div[1]/div/div/div/div[1]/div/div/div[1]/h1/span[2]  timeout=40
    # Run Keyword And Return Status  Click Element When Visible  //*[@id="brandBand_1"]/div/div/div/div/div[1]/div[1]/div[1]/div/div/div/div[1]/div/div/div[1]/h1/span[2]
	# 	Run Keyword And Return Status  Click Element When Visible  (//*[contains(text(),"Select a List View")])[2]
	    
    # ${check3}  Run Keyword And Return Status  Input Text When Element Is Visible    //input[@role="combobox" and contains(@placeholder,"Search")]  ${region_name}         #input text in search icon
    # IF  '${check3}'=='False'
	#     Input Text When Element Is Visible    (//*[@role="combobox"])[2]  ${region_name}
	# END
    # sleep  1
    # Click Element When Visible    //*[@class=" virtualAutocompleteOptionText"]     #select the FP PS HK Wastage  from dropdown menu
    # sleep  1
    Go TO  ${GO_TO_URL_QUEUE}
	${page_load}=    run keyword and return status    page should not contain element    //span[contains(text(),"Refresh this list to view the latest data")]
	IF    "${page_load}" == "False"
		#Run Keyword And Return Status  Click Element  //*[contains(@title,"Refresh")]
        Reload Page
        Go TO  ${GO_TO_URL_QUEUE}
        # Select Region Queue after Goto
        Sleep  2
		wait until page does not contain element    //span[contains(text(),"Refresh this list to view the latest data")]   timeout=80
	END
	sleep  1
    Click Element When Visible  //a/span[contains(text(),"Cases")]     #click on the Cases element because view the table like production

Refresh Page And Wait For List View
	${page_load}=    run keyword and return status    page should not contain element    //span[contains(text(),"Refresh this list to view the latest data")]
	IF    "${page_load}" == "False"
		sleep  1
		#Run Keyword And Return Status  Click Element  //*[contains(@title,"Refresh")]
        Reload Page
        Go TO  ${GO_TO_URL_QUEUE}
        # Select Region Queue after Goto
        Sleep  2
		wait until page does not contain element    //span[contains(text(),"Refresh this list to view the latest data")]   timeout=80
	END

Select Region Queue after Goto
    Wait Until Page Contains Element      //div[@data-aura-class="forceListViewPicker"]   10s
    Wait Until Keyword Succeeds    3X    3s    Click Element When Visible   //div[@data-aura-class="forceListViewPicker"] 
    Wait Until Keyword Succeeds    3X    3s    Input Text When Element Is Visible   //input[@role="combobox" and contains(@placeholder,"Search")]  ${region_name}  
    Wait Until Page Contains Element  (//*[@class=" virtualAutocompleteOptionText"]//mark)[1]      
    ${xpath}=    Set Variable    (//*[@class=" virtualAutocompleteOptionText"]//mark[text()="${region_name}"])[1]
    Wait Until Keyword Succeeds    3x    3s    Execute JavaScript    var element = document.evaluate(`${xpath}`, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; element.click();
    


    

Process Ticket
    [Arguments]  ${iteration}
	${status}=  Run keyword and return status  Wait Until Element Is Visible  //div[@class="slds-scrollable_y"]//tbody/tr[1]/th/span/div//div/a/slot/span  20s
	IF  '${status}' == 'False'
        Return From Keyword
    END
    # Run Keyword And Return Status  Ticket dump into Database
    ${status}  Run Keyword And Return Status    Get Text  //div[@class="slds-scrollable_y"]//tbody/tr[1]/th/span/div//div/a/slot/span
    IF    '${status}' == 'False'
        Return From Keyword  
    END       

    ${ticket_num}=  Get Text  //div[@class="slds-scrollable_y"]//tbody/tr[1]/th/span/div//div/a/slot/span
	Set Tags    ${PandaBotName} processed ${ticket_num} at iteration ${iteration}
    Run Keyword And Return Status  Wait Until Keyword Succeeds    5X   5s     Click Element  //table/tbody/tr/th/span//a[@title="${ticket_num}"]  #open case one

#	check for side tab
    ${start_time} =  Get Current Date  result_format=datetime
    Set Global Variable    ${start_time}
    
	${tab_check}  Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="brandBand_1"]/div/div/div/div/div[2]/div/div[1]/div[3]/div[2]/div[1]/div  10
	IF  "${tab_check}"=="True"
		sleep  1
		Run Keyword And Return Status  Click Element  //*[@id="split-left"]/div/div[2]/button/lightning-primitive-icon  enter
		sleep  1
	END
	${unable_to_load_new_status}    Run Keyword And Return Status    Wait Until Page Contains Element    //a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@aria-selected,"true") and contains(@title,'Unable to load')]/..        5
	IF  '${unable_to_load_new_status}'=='True'
		Sleep  1
		Close This Ticket And Query
		${date} =  Get Current Date  result_format=datetime
		Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`,`panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Unable To Load', 'Ticket was changed to unable to load state','${PandaBotName}', '${start_time}')
	ELSE
		${countweb}=  Get Element Count  //a[contains(@class,"tabHeader slds-context-bar__label-action")]
		IF  ${countweb}==1
			#process ticket
			Log  only ticket tab open
			#change to close other agent tab
			${que_own_status}  Run Keyword And Return Status  Wait Until Element Is Enabled   (((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/../../../../../../../*)[2]//*[contains(text(),"FP PS Wastage Team")]/..  40
			Run Keyword If  '${que_own_status}'=='False'  Close Other Agent Tab  ${ticket_num}  ELSE  Continue Process  ${ticket_num}
		ELSE IF  ${countweb}>1
			Close Previous Opened Tabs  ${countweb}  ${ticket_num}
			Continue Process  ${ticket_num}
		END
	END

Sign To GM For One View
	[Arguments]    ${ticket_num}
    Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="root"]/div/div/div/div[1]/span[2]  5
	Run Keyword And Return Status  Click Element  //*[@id="root"]/div/div/div/div[1]/button  enter
	sleep  1
	Run Keyword And Return Status  Click Element  //*[@id="root"]/div/div/div/div[1]/span[2]  enter
    Unselect Frame
    Run Keyword And Return Status  Click Element  //div/article/div[1]/header/div[2]/button[text()='Refresh']  enter
    Run keyword and return status  Select Frame    ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div[contains(@class,"wsTabset")]//iframe
	sleep  3
	${login_btn_status}  Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="root"]/div/div/div/div[1]/button  5
	sleep  1
	IF  '${login_btn_status}'=='True'
		Log  not signing in go to gmail tab
		Execute Javascript   window.open('https://accounts.google.com/v3/signin/identifier?continue=https%3A%2F%2Fmail.google.com%2Fmail%2F&ifkv=AYZoVhepv0QvMrJerL3VPD_nqQbStNaseMeYSq4UgQKShuN1eBsU6lEvg8q1eRoLC26l88QL8DQN2Q&rip=1&sacu=1&service=mail&flowName=GlifWebSignIn&flowEntry=ServiceLogin&dsh=S17057754%3A1697094375378069&theme=glif')
		sleep  1
		${window_title}  Get Window Titles  
		${window_titless1}=    Get From List    ${window_title}    0
		${window_titless}=    Get From List    ${window_title}    1
		Switch Window  ${window_titless}
		Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="identifierId"]  10
		Run Keyword And Return Status  Input Text    //*[@id="identifierId"]    ${sl_user_name}
		sleep  1
		Run Keyword And Return Status  Click Element    //*[@id="identifierNext"]/div/button/span  enter
		sleep  1
		Run Keyword And Return Status  Input Text    //*[@id="password"]/div[1]/div/div[1]/input  ${gmail_password_onv}
		sleep  1
		Run Keyword And Return Status  Click Element  //*[@id="passwordNext"]/div/button  enter
		sleep  1
		Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="yDmH0d"]/c-wiz/div/div[2]/div/div[1]/div/form/span/section[3]/div/div/section/header/div/h2/span  20
		sleep  1
		Run Keyword And Return Status  Click Element   //*[@id="yDmH0d"]/c-wiz/div/div[2]/div/div[2]/div/div[2]/div/div/button/span  enter
		sleep  1
		Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="yDmH0d"]/c-wiz/div/div[2]/div/div[1]/div/form/span/section[2]/div/div/section/div/div/div/ul/li[2]/div/div[2]  5
		Run Keyword And Return Status  Click Element  //*[@id="yDmH0d"]/c-wiz/div/div[2]/div/div[1]/div/form/span/section[2]/div/div/section/div/div/div/ul/li[2]/div/div[2]
		Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="backupCodePin"]  10
		sleep  60
		Log  Backup code not found enter manualy
		Run Keyword And Return Status  Close Window
        Run Keyword And Return Status    Switch Window  ${window_titless1}
		
		sleep  1
	END
		

Continue Process
    [Arguments]  ${ticket_num}
#	changes for gmail signin
	Run keyword and return status  Select Frame    ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div[contains(@class,"wsTabset")]//iframe
	${signin_check_gm}  Run Keyword And Return Status  Wait Until Page Contains Element  //*[@id="root"]/div/div/div/div[1]/span[2]  5
	IF  '${signin_check_gm}'=='True'
		Sign To GM For One View    ${ticket_num}
	ELSE	
		Log  One View Signed In
	END
	Run keyword and return status  Select Frame    ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div[contains(@class,"wsTabset")]//iframe
	Execute JavaScript    window.scrollTo(0,1300)
	#Scroll Element Into View    //*[@id="root"]/div/div/div[1]/button/span
	Run Keyword And Return Status  Click Element  //*[@id="root"]/div/div/div[1]/button/span  enter
	
	Unselect Frame
	Run Keyword And Return Status  Wait Until Page Contains Element  (//span[contains(text(),'Subject')])[1]  10
    ${ownership_status}=  Run Keyword And Return Status  Take owner ship  ${ticket_num}
    IF  '${ownership_status}'=='True'
        Sleep  2
        Execute JavaScript    window.scrollTo(0,700)
        sleep  1
        Run keyword And Return Status  Wait Until Page Contains Element   //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//span[contains(text(),'Account Name')]/../../span  20
        ${xpath}=    Set Variable    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//records-record-layout-item[@field-label="Account Name"]//records-hoverable-link/div/a)[1]
        Wait Until Keyword Succeeds    3x    3s    Execute JavaScript    var element = document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; element.click();
        Run keyword And Return Status  Wait Until Element Is Enabled  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//span[@title='Platforms Performance']
        
        #Run keyword and return status  Click Link    (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]/div/section/div/div[2]/div/div/div//a[@data-refid="recordId"]/../..//span[contains(text(),'Account Name')]/../../span/a  enter
        #Sleep  3
        Execute JavaScript    window.scrollTo(0,1300)
#        Execute JavaScript    window.scrollTo(0,800)
        #sleep  1
        Set Global Variable    ${contact_email}    ${EMPTY}
        ${email_chk} =    Run Keyword And Return Status    Get Email From Contacts    ${ticket_num}

        IF    '${email_chk}'=='True'
            ${desc_status}  Run Keyword And Return Status  Get Required Info From Description   ${ticket_num}
            IF    '${desc_status}' == 'False'
                Set Screenshot Directory  C:\\Error_Screenshots
                Capture Page Screenshot  ${ticket_num}.png
                ${date} =  Get Current Date  result_format=datetime
                Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Error While Getting Item Description', '${PandaBotName}', '${start_time}')

            END
            sleep  1
            Run Keyword And Return Status  Click Element  (//*[contains(text(),"${ticket_num}")])[1]/../../div[2]/button
            sleep  1
            Run Keyword And Return Status  Click Element  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
            Run Keyword And Return Status  Click Element  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/div[1]/a
        ELSE
            ${date} =  Get Current Date  result_format=datetime
            Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Contact Email Not Found', '${PandaBotName}', '${start_time}')
            #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Contact Email Not Found')
#						    Unselect Frame
            ${countTabs}=  Get Element Count  (//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")]
            FOR  ${J}  IN RANGE  1  ${countTabs+1}
                Sleep  1
                Click Element When Visible  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")])[1]
            END
            run keyword and return status  Scroll Element Into View  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
            ${ow_st}  Run Keyword And Return Status   Wait Until Page Contains Element  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  5
            Run Keyword If  '${ow_st}'=='True'  Give back Owner ship  ${ticket_num}
            sleep  1
        END
    ELSE
        ${date} =  Get Current Date  result_format=datetime
        Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Failed To Take Ownership', '${PandaBotName}', '${start_time}')

        #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Failed To Take Ownership')
#						Unselect Frame
        #close tab here
        Run Keyword And Return Status  Wait Until Page Contains Element    (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${ticket_num}')]/../div[2])[1]
        Run Keyword And Return Status  Click Element When Visible    (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${ticket_num}')]/../div[2])[1]/button
        Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  20
        Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
    END

Close Other Agent Tab
    [Arguments]  ${ticket_num}
    run keyword and return status  Wait Until Page Contains Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${ticket_num}')]/../div[2])[1]/button  5
    run keyword and return status  Click Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${ticket_num}')]/../div[2])[1]/button
    ${date} =  Get Current Date  result_format=datetime
    Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Other Agent Tab', '${PandaBotName}', '${start_time}')

    #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Other Agent Tab')
    Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  20
    Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a

Take owner ship
        [Arguments]  ${ticket_num}
        sleep  2
        Execute JavaScript    window.scrollTo(0,450)
        sleep  2
        Run Keyword And Return Status  Wait Until Element Is Enabled   ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}")]))[2]/ancestor::div[@class="oneWorkspace active hasFixedFooter navexWorkspace"]//*[contains(text(),"FP PS Wastage Team")]/../../../../../../following-sibling::button[@title="Edit Case Owner"]
        FOR  ${I}  IN RANGE  0  5
			Run keyword And Return Status  Click Element When Visible  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}")]))[2]/ancestor::div[@class="oneWorkspace active hasFixedFooter navexWorkspace"]//*[contains(text(),"FP PS Wastage Team")]/../../../../../../following-sibling::button[@title="Edit Case Owner"]
            ${panda_bot_st}  Run keyword And Return Status  Wait Until Element Is Enabled  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div//input[@placeholder="FP PS Wastage Team"]/../../following-sibling::div/button  5
			exit for loop if  '${panda_bot_st}'=='True'
		END
		#run keyword and return status  Click Element When Visible  (((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div//span[contains(text(),"FP PS Wastage Team")])/../../button  enter
        Sleep  2
        Wait Until Element Is Enabled  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div//input[@placeholder="FP PS Wastage Team"]/../../following-sibling::div/button  20
        Click Element When Visible  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div//input[@placeholder="FP PS Wastage Team"]/../../following-sibling::div/button  enter
        Sleep  2
        ${queueStatus}=  run keyword and return status  Click Element  ((((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div//input[contains(@placeholder,"Search...")]))/ancestor::lightning-grouped-combobox//button  enter
        Click Element When Visible    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//lightning-base-combobox-item[@data-value="User"]
        Input Text When Element Is Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//input[@placeholder="Search..."]  ${PandaBotName}
        Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//ul[@role="group"]/li//lightning-base-combobox-formatted-text[@title='${PandaBotName}']
        Scroll Element By Xpath    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]
        Click Element When Visible    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]  enter
        Sleep  2
        
        
        
Check Ownership Assigned
    [Arguments]  ${PandaBotName}  ${assigned_bot}  ${ticket_num}
    IF  "${PandaBotName}" != "${assigned_bot}"
        
        
        # Adding entry in databse
        ${date} =  Get Current Date  result_format=datetime
        Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`, `ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'The assigned bot name ${assigned_bot} mismatched with current panda bot ${PandaBotName}','${PandaBotName}', '${start_time}')
    
        Set Screenshot Directory  C:\\Error_Screenshots
        Capture Page Screenshot  ${ticket_num}.png
        # Send Email
        Send Email    [Alert] ${PandaBotName} assigned a wrong ticket   The assigned bot name ${assigned_bot} mismatched with current panda bot ${PandaBotName} on ticket number ${ticket_num}     
        ...    delivery.alerts@autosphere.ai
        
        Fail  The assigned bot name ${assigned_bot} mismatched with current panda bot ${PandaBotName}
    END
Close This Ticket And Query
	Run Keyword And Return Status  Click Button   //a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@aria-selected,"true") and contains(@title,'Unable to load')]/../div[2]/button
	Sleep  0.5
	Run Keyword And Return Status  Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
	Sleep  0.5
	Reload Page
	Run Keyword And Return Status  Wait Until Page Contains Element  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a 20

Close Previous Opened Tabs
    [Arguments]  ${countweb}  ${ticket_num}
    ${help_var}  Set Variable  ${0}
    FOR  ${I}  IN RANGE  1  ${countweb}
		${I}  Evaluate  ${I} - ${help_var}
		Wait Until Keyword Succeeds  3x  3s  Click Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])[${I}]
		${unable_to_load_new_status}    Run Keyword And Return Status    Wait Until Page Contains Element    //a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@aria-selected,"true") and contains(@title,'Unable to load')]/..        5
	    IF  '${unable_to_load_new_status}'=='True'
		    Close This Ticket And Query
			${help_var}  Evaluate  ${help_var} + 1
		ELSE
			sleep  0.5
            Execute JavaScript    window.scrollTo(200,0)
			sleep  0.5
            ${TT}=  Get Text  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])[${I}]
            Sleep  2
			${TT}=  Replace String  ${TT}  ${SPACE}|${SPACE}Case  ${EMPTY}
#            Sleep  4
            #Click Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])[${I}]
#            sleep  2
			#sub tabs count
            ${countTabs}=  Get Element Count  (//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")]
            IF  ${countTabs}==0
                #no sub tabs found
                Log  No Subtabs Found
            ELSE
                #close sub tabs
                FOR  ${J}  IN RANGE  1  ${countTabs+1}
                    Sleep  1
                    Click Element When Visible  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")])[1]
                END
            END
            sleep  1
            Execute JavaScript    window.scrollTo(0,300)
            sleep  1
            ${list_st}=  Run Keyword And Return Status  Wait Until Page Contains Element  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ]/ancestor::section[@aria-expanded="true"]//slot[contains(text(),"FP PS Wastage Team")]/..  10   #FP PS wastage team ownership
            IF  '${list_st}'=='True'
				Log  ${TT}
				Log  ${ticket_num}
                IF  '${TT}' != '${ticket_num}'
                    run keyword and return status  Scroll Element Into View  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${TT}')]/../div[2])[last()]
                    run keyword and return status  Click Element When Visible   (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${TT}')]/../div[2])[last()]
                    ${help_var}  Evaluate  ${help_var} + 1
                    sleep  1.5
                END
            ELSE
                #close if resolved tab exists
                ${resolve_tab_check}    ${help_var}    Check If Tab Exists    ${TT}    ${I}    ${help_var}
                IF    "${resolve_tab_check}"=="False"
                    #making changes for giving back ownership_status
                    run keyword and return status  Scroll Element Into View  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
                    ${ow_st}  Run Keyword And Return Status   Wait Until Page Contains Element  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  5
                    #Run Keyword If  '${ow_st}'=='True'  Take back Owner ship  ${TT}
					IF  '${ow_st}'=='True'
                        Give back Owner ship Prev Tab  ${TT}   ${I}
                        sleep  2
						${help_var}  Evaluate  ${help_var} + 1
                    END
                    sleep  1
                ELSE
                    Log   tab closed
                END
            END
        END
    END

Give back Owner ship Prev Tab
    [Arguments]  ${tick_num}   ${p}
    sleep  1
    ${queue_name}=  Get Text  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]/..//force-lookup//span//span
    log  ${queue_name}
    IF  "${queue_name}" == "FP PS Wastage Team"
        log  ticket close
        Click Element When Visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${tick_num}')]/../div[2])[${p}]/button
    ELSE
        Scroll Element By Xpath    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
        Wait Until Element Is Enabled  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  40
        FOR  ${I}  IN RANGE  0  5
            Run keyword And Return Status  Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  enter
            ${panda_bot_st}  Run keyword And Return Status  Wait Until Element Is Enabled  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//label[contains(text(),'Case Owner')]/../div//button[@title="Clear Selection"]  2
            exit for loop if  '${panda_bot_st}'=='True'
        END
        Sleep  1
        Execute JavaScript    window.scrollTo(0,300)
        #sleep  1
        Wait Until Element Is Enabled  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//label[contains(text(),'Case Owner')]/../div//button[@title="Clear Selection"]  40
        Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//label[contains(text(),'Case Owner')]/../div//button[@title="Clear Selection"]  enter
        #Sleep  2
        Click Element When Visible    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@data-value="User"]
        Click Element When Visible    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//lightning-base-combobox-item[@data-value="Group"]
        Input Text When Element Is Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//input[@placeholder="Search..."]  FP PS Wastage Team
        Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//ul[@role="group"]/li//lightning-base-combobox-formatted-text[@title='FP PS Wastage Team']
        Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//*[contains(text(),'Status')]/../..//button
        Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//*[@title="In Progress"]
        Scroll Element By Xpath    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]
        Click Element When Visible    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]  enter
        sleep  3
        run keyword and return status  Wait Until Page Contains Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${tick_num}')]/../div[2])[${p}]  20
        run keyword and return status  Click Element When Visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${tick_num}')]/../div[2])[${p}]/button
    END
Other Agent Tab Close
    [Arguments]  ${TT}    ${I}    ${help_var}
    Set Local Variable    ${return_flag}    ${EMPTY}
    ${panda_bot_st}  Run keyword And Return Status  Wait Until Element Is Enabled  ((((//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ]))[2]/ancestor::div//span[contains(text(),"${PandaBotName}")])/../a)  2
    IF  '${panda_bot_st}'=='False'
        run keyword and return status  Wait Until Page Contains Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${TT}')]/../div[2])[${I}]/button  5
        run keyword and return status  Click Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${TT}')]/../div[2])[${I}]/button
        ${help_var}  Evaluate  ${help_var} + 1
        Set Local Variable    ${return_flag}    True
    END
    return from keyword      ${return_flag}		${help_var}

Check If Tab Exists
    [Arguments]  ${TT}    ${I}    ${help_var}
    Set Local Variable    ${return_flag}    ${EMPTY}
    #${panda_own_status}    Run Keyword And Return Status    Wait Until Page Contains Element    ((((//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ]))[2]/../../../../../../../*)[2]//*[contains(text(),"${PandaBotName}")]/..)[1]    1
    ${resolve_status}    Run Keyword And Return Status    Wait Until Page Contains Element    ((((//span[contains(@class,"title slds-truncate") and contains(text(),"${TT}") ]))[2]/../../../../../../../*)[2]//*[contains(text(),"Resolved")]/..)[1]    1
    ${unable_to_load_status}    Run Keyword And Return Status    Wait Until Page Contains Element    //a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@aria-selected,"true") and contains(@title,'Unable to load')]/..        1
    IF  '${resolve_status}'=='True'
        sleep  1
        Click Element   (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${TT}')]/../div[2])[${I}]
        ${help_var}  Evaluate  ${help_var} + 1
        Set Local Variable    ${return_flag}    True
    ELSE IF    '${unable_to_load_status}'=='True'
        Click Button   //a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@aria-selected,"true") and contains(@title,'Unable to load')]/../div[2]/button
        ${help_var}  Evaluate  ${help_var} + 1
        Set Local Variable    ${return_flag}    True
    ELSE
        Set Local Variable    ${return_flag}    False
    END
    return from keyword      ${return_flag}		${help_var}

Give back Owner ship
    [Arguments]  ${tick_num}
    sleep  1
    Scroll Element By Xpath    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
    Wait Until Element Is Enabled  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  40
    FOR  ${I}  IN RANGE  0  5
		Run keyword And Return Status  Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  enter
		${panda_bot_st}  Run keyword And Return Status  Wait Until Element Is Enabled  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//label[contains(text(),'Case Owner')]/../div//button[@title="Clear Selection"]  2
		exit for loop if  '${panda_bot_st}'=='True'
	END
	Sleep  1
    Execute JavaScript    window.scrollTo(0,300)
    #sleep  1
    Wait Until Element Is Enabled  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//label[contains(text(),'Case Owner')]/../div//button[@title="Clear Selection"]  40
    Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//label[contains(text(),'Case Owner')]/../div//button[@title="Clear Selection"]  enter
    #Sleep  2
    Click Element When Visible    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[@data-value="User"]
    Click Element When Visible    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//lightning-base-combobox-item[@data-value="Group"]
    Input Text When Element Is Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//input[@placeholder="Search..."]  FP PS Wastage Team
    Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//ul[@role="group"]/li//lightning-base-combobox-formatted-text[@title='FP PS Wastage Team']
    Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//*[contains(text(),'Status')]/../..//button
    Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//*[@title="In Progress"]
    Scroll Element By Xpath    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]
    Click Element When Visible    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${tick_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]  enter
    sleep  3
    run keyword and return status  Wait Until Page Contains Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${tick_num}')]/../div[2])[1]  20
    run keyword and return status  Click Element When Visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${tick_num}')]/../div[2])[1]/button

Get Email From Contacts
    [Arguments]    ${ticket_num}
    Run Keyword And Return Status  Wait Until Page Contains Element   Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//*[contains(text(),'View All')]/../..//span[@title='Contacts']/..  20
	Wait Until Keyword Succeeds  5x  3s  Click Element When visible    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//*[contains(text(),'View All')]/../..//span[@title='Contacts']/..  enter
    ${acc_st}  Run keyword And Return Status  Wait Until Element Is Enabled  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr    2
    
	
    ${count} =  Get WebElements  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr
    ${count}=    Get length    ${count}
    Log  total row:${count}
    @{contact_email}  Create List
	IF  ${count} == 1
        ${mail}=   Get Text    (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[1]/td[4]
		Append To List  ${contact_email}  ${mail}
        Click Element When Visible   (//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}")])[2]   enter  # (//*[contains(text(),'${ticket_num}')])
        Click Element When Visible   (//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}")])[2]   enter  # (//*[contains(text(),'${ticket_num}')])
        Wait Until Page Contains Element    ((//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//records-record-layout-item[@field-label="Description"])[1]//span)[1]  40
    ELSE
        @{wastage}  Create List
        @{billing_manager}    Create List
        @{Owner_list}    Create List
        FOR  ${item}  IN RANGE   1    ${count}+1
            Scroll Element Into View  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[${item}]/th
            ${case_item1}=  Get Text  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[${item}]/th
            IF  'wastage' in '''${case_item1}''' or 'Wastage' in '''${case_item1}'''
                Log   Condition is satisfied ${case_item1}
                ${email}=  Get Text  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[${item}]/td[4]
                Append To List  ${wastage}  ${email}
            END
        END
        FOR  ${item}  IN RANGE   1    ${count}+1
            Scroll Element Into View  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[${item}]/td[3]
            ${case_item1}=  Get Text  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[${item}]/td[3]
            IF  '${case_item1}' == 'Billing Manager' or '${case_item1}' == 'Billing Manger'
                Log   Condition is satisfied ${case_item1}
                ${email}=  Get Text  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[${item}]/td[4]
                Append To List  ${billing_manager}  ${email}
            ELSE IF    '${case_item1}' == 'Owner'
                Log   Condition is satisfied ${case_item1}
                ${email}=  Get Text  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[${item}]/td[4]
                Append To List  ${Owner_list}  ${email}
            END
        END
        Log    ${billing_manager}
        Log    ${wastage}
        Log    ${Owner_list}
        ${billing_length}    Get Length    ${billing_manager}
        ${wastage_length}    Get Length    ${wastage}
        IF  ${wastage_length} > 0
            ${contact_email}    set variable      ${wastage}
        ELSE IF   ${billing_length} > 0
            ${contact_email}    set variable      ${billing_manager}
        ELSE
            ${contact_email}    set variable    ${Owner_list}
        END
    END
    Log    ${contact_email}
    ${isEmpty}    Run Keyword And Return Status    Should Be Empty      ${contact_email}
    IF  '${isEmpty}'=='${True}'
		run keyword and return status    Get Email Value
	END
	Log    ${contact_email}
	Set Global Variable    ${contact_email}    ${contact_email}

Get Email Value
    ${email_id}=  Get Text  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[1]/td[4]
	IF  '${email_id}'=='${EMPTY}'
		${email_id}=  Get Text  (//*[contains(@class,'slds-table slds-table_header-fixed slds-table_bordered slds-table_edit slds-table_resizable-cols')])[2]/tbody/tr[2]/td[4]
	END
    Append To List   ${contact_email}  ${email_id}
    set global variable    ${contact_email}    ${contact_email}


Get Required Info From Description
    [Arguments]  ${ticket_num}
    Set Local Variable  ${keywordStatus}  True
    Set local variable  ${Issue_Type}  ${EMPTY}
    Set local variable  ${Order_Num}  ${EMPTY}
    Set local variable  ${Order_Date}  ${EMPTY}
    Set local variable  ${Quantity}  ${EMPTY}
    Set local variable  ${Removed_Item}  ${EMPTY}
    Set local variable  ${Amount_Removed}  ${EMPTY}
	sleep  1
    Click Element When Visible   (//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}")])[2]   enter  # (//*[contains(text(),'${ticket_num}')])
    Wait Until Page Contains Element    ((//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//records-record-layout-item[@field-label="Description"])[1]//span)[1]  40
    ${description}=  Get Text   ((//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//records-record-layout-item[@field-label="Description"]//lightning-formatted-text)[1])[1]
    ${description}=    Remove Emojis    ${description}
    #${description}=  Convert To String  ${description}
	@{words} =  Split String  ${description}  \n
    FOR  ${i}  IN  @{words}
        @{Order} =  Split String  ${i}  :

        ${lines} =  Get Lines Containing String  ${i}  Order
        ${length} =  Get Length  ${lines}
        IF  '${length}' != '0'
            Log   ${Order}[1]
            ${str} =  Remove String  ${Order}[1]  ${SPACE}
            Set Local variable  ${Order_Num}  ${str}

        END
        ${lines} =  Get Lines Containing String  ${i}  Quantity
        ${length} =  Get Length  ${lines}
        IF  '${length}' != '0'
            Log   ${Order}[1]
            Set Local variable  ${Quantity}  ${Order}[1]
        END
        ${lines} =  Get Lines Containing String  ${i}  Issue
        ${length} =  Get Length  ${lines}
        IF  '${length}' != '0'
            Log   ${Order}[1]
            #changes for email issue type translate
            set global variable  ${Issue_Type_english}  ${Order}[1]
            ${translated_text} =    Get Translated Text    ${Order}[1]
            Set Local variable  ${Issue_Type}  ${translated_text}
        END
    END
    IF  '${Issue_Type}'!= '${EMPTY}' or '${Order_Num}'!= '${EMPTY}'
        ${order_check}=  Evaluate   "Item" in """${Order_Num}"""
        IF  '${order_check}'=='True'
            @{new_order_num}  Split String  ${Order_Num}  Item
            Set Local Variable  ${Order_Num}  ${new_order_num}[0]
        END
        Sleep  0.1s
        Select Frame    ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]))[2]/ancestor::div[contains(@class,"wsTabset")]//iframe
        Sleep  2s
        Execute JavaScript    window.scrollTo(0,1300)
        ${xpath}=    Set Variable    //button//span[contains(text(),'Sign In')]
        ${signin_Status}=  Run Keyword and return status  Execute JavaScript    var element = document.evaluate("${xpath}", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; element.click();
        Unselect Frame
        IF  '${signin_Status}'=='True'
            ${Status}=  Run Keyword and return status  Wait Until Page Contains Element  (//*[contains(text(),"Vendor name")])[1]/../div
            IF  '${Status}'=='False'
                Execute Javascript   window.open('https://accounts.google.com/v3/signin/identifier?continue=https%3A%2F%2Fmail.google.com%2Fmail%2F&ifkv=AYZoVhepv0QvMrJerL3VPD_nqQbStNaseMeYSq4UgQKShuN1eBsU6lEvg8q1eRoLC26l88QL8DQN2Q&rip=1&sacu=1&service=mail&flowName=GlifWebSignIn&flowEntry=ServiceLogin&dsh=S17057754%3A1697094375378069&theme=glif')
                sleep  1
                
                ${window_title}  Get Window Titles  
                ${window_titless1}=    Get From List    ${window_title}    0
                ${window_titless}=    Get From List    ${window_title}    1
                Switch Window  ${window_titless}
                Run Keyword And Return Status    Input Text When Element Is Visible  //input[@name="identifier"]  ${sl_user_name}
                Run Keyword And Return Status  Click Element When Visible    //*[contains(text(),'Next')]  enter
                #Run Keyword And Return Status  Wait Until Page Contains Element  //*[@data-email='${sl_user_name}']/..  10
                #Run Keyword And Return Status  Click Element When Visible    //*[@data-email='${sl_user_name}']/..
                Sleep  2s
                Run Keyword And Return Status  Input Text When Element Is Visible    //input[@name='Passwd']    ${gmail_password_onv}
                sleep  1
                Run Keyword And Return Status  Click Element When Visible    //*[contains(text(),'Next')]  enter
                sleep  4s
                Run Keyword And Return Status  Close Window
                Run Keyword And Return Status    Switch Window  ${window_titless1}
                Run Keyword And Return Status    Select Frame    //div[@class='slds-card__body']/iframe
		        #Run Keyword And Return Status    Click Element When Visible    //span[contains(text(),'Try Again')]
                ${xpath}=    Set Variable    //span[contains(text(),'Try Again')]
                ${signin_Status}=  Run Keyword and return status  Execute JavaScript    var element = document.evaluate("${xpath}", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; element.click();
                Unselect Frame
                Sleep  5s
            END
            Sleep  3s
            Log  User is signed in
        END
        #${View_more_st}=  run keyword and return status  Mouse Over  //*[contains(text(),'View more')]
        IF   '${Order_Num}'!= '${EMPTY}'
            #Unselect Frame
            ${vendor_name}=  Get text  (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//records-record-layout-item[@field-label="Account Name"]//records-hoverable-link/div/a//span)[1]
            ${SUM}  ${itm}=  Extract Required Info From Discription   ${description}
            ${isEmpty}    Run Keyword And Return Status    Should Be Empty      ${contact_email}
            IF    '${isEmpty}'=='True'
                ${date} =  Get Current Date  result_format=datetime
                Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Contact Email Not Found', '${PandaBotName}', '${start_time}')

                #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Contact Email Not Found')
                Unselect Frame
                ${countTabs}=  Get Element Count  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")]
				FOR  ${J}  IN RANGE  1  ${countTabs+1}
					Sleep  1
					Click Element When Visible  (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")])[1]
				END
				run keyword and return status  Scroll Element Into View  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
                ${ow_st}  Run Keyword And Return Status   Wait Until Page Contains Element  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  5
                Run Keyword If  '${ow_st}'=='True'  Give back Owner ship  ${ticket_num}
				sleep  1
                Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  40
                Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
                Set Local Variable  ${keywordStatus}  False
            ELSE
                Email Formating   ${Order_Num}  ${SUM}  ${Issue_Type}  ${Order_Date}  ${vendor_name}  ${ticket_num}  ${contact_email}  ${itm}
            END
            Set Local Variable  ${keywordStatus}  True
        ELSE
            Unselect Frame
            Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  40
            Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
            Set Local Variable  ${keywordStatus}  False
        END
    ELSE
        ${date} =  Get Current Date  result_format=datetime
        Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Issue Type Or Order Number is Missing', '${PandaBotName}', '${start_time}')

		#Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Issue Type Or Order Number is Missing')
        Unselect Frame
        Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  40
        Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
        Set Local Variable  ${keywordStatus}  False
    END
    [Return]  ${keywordStatus}
Extract Required Info From Discription
    [Arguments]  ${description}
    @{itemss}  Create List
    @{itemss_qan}  Create List
    @{itemss_price}  Create List
    log  ${description}
    @{words} =  Split String  ${description}  \n
        FOR  ${i}  IN  @{words}
              ${itemss}  ${itemss_qan}  ${itemss_price}  Do Formating on String  ${i}  ${itemss}  ${itemss_qan}  ${itemss_price}  Quantity
              ${itemss}  ${itemss_qan}  ${itemss_price}  Do Formating on String  ${i}  ${itemss}  ${itemss_qan}  ${itemss_price}   Topping(s):
        END
    ${itemss_qan}  ${itemss_price}  Get Total Amount   ${itemss}  ${itemss_qan}  ${itemss_price}
    ${SUM}=  Compute Sum  ${itemss_qan}  ${itemss_price}
    Log  ${itemss}
    Log  ${itemss_qan}
    Log  ${itemss_price}
    Log  ${SUM}
    @{temp}=  Create List
    FOR  ${I}  IN  @{itemss}
        ${itmStatus}=  Evaluate   "0 x " in """${I}"""
        IF  '${itmStatus}'!='True'
            Append To List   ${temp}   ${I}
        END
    END
    @{itemss}  copy list   ${temp}
    ${itm}=  Evaluate  ", ".join($itemss)
    [Return]  ${SUM}  ${itm}

Do Formating on String
     [Arguments]  ${i}  ${itemss}  ${itemss_qan}  ${itemss_price}  ${to_get}
     ${lines} =  Get Lines Containing String  ${i}   ${to_get}
    ${length} =  Get Length  ${lines}
    IF  '${length}' != '0'
        Log    ${lines}
        @{Items} =  Split String  ${lines}  ,
        FOR  ${j}  IN  @{Items}
            Log    ${j}
            @{first_item} =  Split String  ${j}  :${SPACE}
            ${ln} =  Get Length  ${first_item}
            IF  '${ln}' != '1'
                Append To List  ${itemss}  ${first_item}[1]
            ELSE
                Append To List  ${itemss}  ${j}
            END
        END
    END
    [return]    ${itemss}  ${itemss_qan}  ${itemss_price}

Get Total Amount
    [Arguments]   ${itemss}  ${itemss_qan}  ${itemss_price}

    FOR  ${i}  IN  @{itemss}
        Log  ${i}
        @{Items_Quan} =  Split String  ${i}  ${SPACE}x${SPACE}
        ${st}=  Run keyword and return status  log  ${Items_Quan}[1]
        IF  '${st}'=='True'
            Log  ${Items_Quan}[1]
            ${test} =  Get Regexp Matches  ${Items_Quan}[1]  (HKD\\s?)([\\d]*[.][\\d]|[\\d]+)   #[A-Za-z + ( ) / -]
            ${re_status}=  run keyword and return status  Log  ${test}[0]
            IF  '${re_status}'=='True'
                ${Test}=   Remove String  ${test}[0]  ${SPACE}  HKD
                Append to List  ${itemss_price}  ${Test}
                ${quan}=   Remove String  ${Items_Quan}[0]  ${SPACE}
                Append to List  ${itemss_qan}  ${quan}
                log  ${itemss_qan}
            END
        END
    END
    Log  ${itemss_qan}
    Log  ${itemss_price}
    [return]  ${itemss_qan}  ${itemss_price}

Compute Sum
    [Arguments]  ${itemss_qan}  ${itemss_price}
    ${ln} =  Get Length  ${itemss_qan}
    ${Sum}=  EVALUATE   0 + 0
    FOR  ${i}  IN RANGE  0  ${ln}
        ${Sum}=  EVALUATE   ${itemss_qan}[${i}]*${itemss_price}[${i}]+${Sum}
    END
    [Return]  ${Sum}


Get Translated Text
    [Arguments]    ${issue_type_str}
    Set Global Variable  ${translated_text}    ${EMPTY}
    Open Workbook  ${HOME_Path}\\Translation.xlsx
    ${worksheet}=    Read worksheet As Table   Hong Kong  header=true
    FOR    ${i}   IN  @{worksheet}
        Log    ${i}[English]
		${issue_type_str}  Strip String  ${issue_type_str}
		${val_comp}  Strip String  ${i}[English]
        IF    '${val_comp}' == '${issue_type_str}'
			Log  ${i}[Cantonese]
			Log  ${issue_type_str}
            Set Global Variable  ${translated_text}    ${i}[Cantonese]
            exit for loop
        END
    END
    IF   '${translated_text}'=='${EMPTY}'
        Set Global Variable    ${translated_text}      ${issue_type_str}
    END
    return from keyword    ${translated_text}

Email Formating
    [Arguments]   ${Order_Num}  ${SUM}  ${Issue_Type}  ${Order_Date}  ${vendor_name}  ${ticket_num}  ${contact_email}  ${itm}
    Set Global Variable  ${vendor_name}  ${EMPTY}
    Set Global Variable  ${Order_Date}  ${EMPTY}
    #split order number
    @{order_code_split} =  Split String  ${Order_Num}  -

    ${ordercode_part1}  Set Variable  ${order_code_split}[0]
    ${ordercode_part1}  Strip String  ${ordercode_part1}

    ${ordercode_part2}  Set Variable  ${order_code_split}[1]
    ${ordercode_part2}  Strip String  ${ordercode_part1}
    sleep  2
    Execute JavaScript    window.scrollTo(300,0)
    ${iframe_status}  Run Keyword And Return Status  Wait Until Page Contains Element  (//iframe)[1]  5
    Run Keyword And Return Status  Select Frame  (//iframe)[1]
    #${vendorId_status}  Run Keyword And Return Status  Wait Until Page Contains Element  (//*[contains(text(),"ID: ${ordercode_part1}")])[1]  2
	
    ${vendorId_status}  Run Keyword And Return Status  Wait Until Page Contains Element  (//*[contains(text(),"Vendor name")])[1]/../div  10
    IF  '${vendorId_status}'=='True'
        #${vendor_name}  Get Text  (//*[contains(text(),"ID: ${ordercode_part1}")])[1]/../..//div[contains(text(),"Vendor Name")]/../h4/span/a
        Scroll Element By Xpath  (//*[contains(text(),"Vendor name")])[1]/../div
	    ${vendor_name}  Get Text   (//*[contains(text(),"Vendor name")])[1]/../div
        #Execute JavaScript    window.scrollTo(0,200)
        #sleep  2
        #${Order_Date}  Get Text  (//*[contains(text(),"ID: ${ordercode_part1}")])[2]/../../..//*[contains(text(),'Created')]/../span[2]
        Scroll Element By Xpath  (//*[contains(text(),"Created time")])[1]/../div
	    ${Order_Date}  Get Text  (//*[contains(text(),"Created time")])[1]/../div

        #Execute JavaScript    window.scrollTo(0,1400)
        
        Run Keyword And Return Status  Wait Until Page Contains Element  //div[@data-widget-name="order_invoice"]  10

        Scroll Element By Xpath  //div[@data-widget-name="order_invoice"]
        Sleep  2s
        ${xpath}=    Set Variable    //div[@data-widget-name="order_invoice"]
        Wait Until Keyword Succeeds    3x    3s    Execute JavaScript    var element = document.evaluate('${xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; element.click();
        
        Run Keyword And Return Status  Wait Until Page Contains Element  (//*[@data-test-id="order-invoice-basket-value"]//span)[last()]  5

        ${total_amount}  Get Text  (//*[@data-test-id="order-invoice-basket-value"]//span)[last()]
        log  ${total_amount}

        Unselect Frame
        ${vendor_name}  Replace String   ${vendor_name}  '  ${EMPTY}
        ${Order_Date}  Replace String   ${Order_Date}  '  ${EMPTY}
        IF  '${vendor_name}'!='${EMPTY}' and '${Order_Date}'!='${EMPTY}'
            sleep  1
            ${message}=  Get File  Honkong_Email.txt
            ${message} =  Replace String  ${message}  %issue type%  ${Issue_Type}
            ${message} =  Replace String  ${message}  %vendor name%  ${vendor_name}
            ${message} =  Replace String  ${message}  %order num%  ${Order_Num}
            ${message} =  Replace String  ${message}  %issue type eng%  ${Issue_Type_english}
            ${message} =  Replace String  ${message}  %removed item%   ${itm}
            ${message} =  Replace String  ${message}  %order date%  ${Order_Date}
            ${message} =  Replace String  ${message}  %total amount%  ${total_amount}
            ${message} =  Replace String  ${message}  %amount removed%  ${SPACE}${SUM}${EMPTY}
            log  ${message}
            ${Issue_Type}=  Replace String  ${Issue_Type}  '  ${EMPTY}
            ${vendor_name}=  Replace String  ${vendor_name}  '  ${EMPTY}
            ${Order_Num}=  Replace String  ${Order_Num}  '  ${EMPTY}
            ${itm}=  Replace String  ${itm}  '  ${EMPTY}
            ${Order_Date}=  Replace String  ${Order_Date}  '  ${EMPTY}
            ${SUM}=  Replace String  ${SPACE}${SUM}${EMPTY}  '  ${EMPTY}
            IF  '${Issue_Type}'!='${EMPTY}'and'${vendor_name}'!='${EMPTY}'and'${Order_Num}'!='${EMPTY}'and'${itm}'!='${EMPTY}'and'${Order_Date}'!='${EMPTY}'and'${SUM}'!='${EMPTY}'
                Wait Until Page Contains Element    ((//*[contains(text(),'${ticket_num}')])[2]/ancestor::*)[6]//*[contains(text(),'Write an email...')]  40
                Execute JavaScript    window.scrollTo(600,0)
                Wait Until Page Contains Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//span[contains(text(),'Compose')]  20
                Click Element   (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//span[contains(text(),'Compose')]  enter
                ${email_butn_chk}  Run Keyword And Return Status  Wait Until Page Contains Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="To"]  40
                IF  '${email_butn_chk}'=='True'
                    run keyword and return status  Click Element when visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="To"]/../..//button[contains(@class,"slds-pill__remove slds-button_reset")]
                END
                sleep  0.5
                Execute JavaScript    window.scrollTo(0,200)
                sleep  0.5
                Close Previous Email tabs
                ${emails}=    Catenate    SEPARATOR=,    @{contact_email}
                Input Text    (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="To"]/../..//input[contains(@role,"combobox")]   ${emails}   #${contact_email}
                Run keyword and return status  Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//a[@href="Bcc"]  enter
                Run keyword and return status  Input Text When Element Is Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//label/span[contains(text(),"Bcc")]/../..//input[@role="combobox"]  support@foodpanda.my
                ${testFrame}=  Get Element Attribute  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]  name
                Sleep  1
                Clear Element Text  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="Subject"]/../../input
                Input Text   (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="Subject"]/../../input   [ ${vendor_name} ] ] Item(s) Removal Notification / 取消訂單部分款項通知  [ ${Order_Num} ]
                Select Frame  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]
                Sleep  2
                ${test}=  Get Element Attribute  //html/head/link[1]  href
                Select Frame  (//iframe)[1]
                sleep  1
				log  ${total_amount}
                ${STtausCR}=  Run keyword and ignore error  Attached Foodpanda Temp CR    ${vendor_name}    ${OrderDate}    ${Order_Num}    ${itm}    ${Issue_Type_english}    ${SPACE}${SUM}${EMPTY}    ${total_amount}  ${ticket_num}  ${Issue_Type}
                IF  '${STtausCR}[0]' == 'FAIL'
                    Set Tags  ${PandaBotName} Failed on :${STtausCR}[1]
                    Fail  ${PandaBotName} Failed on :${STtausCR}[1]
                END
                #${emailSt}=  Run keyword and return status  Input Text  //html/body/center/table/tbody/tr[3]/td/table/tbody/tr/td/div[1]   ${message}
                # IF  '${emailSt}'=='False'
                     #     Run keyword and return status  Input Text  //html/body/center/table/tbody/tr[3]/td   ${message}
                #END
                sleep  10s
                Unselect Frame
                Execute JavaScript    window.scrollTo(0,800)
                Scroll Element Into View  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="Send"]
                run keyword and return status    Click Element When Visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="Send"]/..  enter
                Sleep  7
                run keyword and return status  Click Element When Visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="Send"]/..  enter
                Sleep  2
                Run Keyword And Return Status    Click Element If Visible  //*[contains(text(),"Don't show this message again")]/..
                Run Keyword And Return Status    Click Element If Visible  //button[contains(text(),"Attach and Send")]
                ${emails}=    Catenate    SEPARATOR=,    @{contact_email}
#                Save Record To Excel  ${emails}  ${ticket_num}
                Close Case  ${ticket_num}
            ELSE
                ${date} =  Get Current Date  result_format=datetime
                Set Local Variable  ${DBComments}  Missing One Of Required Information. Issue type: 
                Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', '${DBComments}', '${PandaBotName}', '${start_time}')

                #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', '${DBComments}')
                FOR  ${I}  IN RANGE  1  10
                    ${caseStatus}=  run keyword and return status  Wait Until Page Contains Element  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  5
                    Exit For Loop If  '${caseStatus}'=='True'
                    Run Keyword If  '${caseStatus}'=='False'  Go Back
                END
                ${countTabs}=  Get Element Count  (//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")]
                FOR  ${J}  IN RANGE  1  ${countTabs+1}
                    Sleep  1
                    Click Element When Visible  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")])[1]
                END
                sleep  1
                #making changes for giving back ownership_status
                run keyword and return status  Scroll Element Into View  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
                ${ow_st}  Run Keyword And Return Status   Wait Until Page Contains Element  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  5
                Run Keyword If  '${ow_st}'=='True'  Give back Owner ship  ${ticket_num}
                sleep  1

                Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  40
                Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
            END
        ELSE
            ${date} =  Get Current Date  result_format=datetime
		    Set Local Variable  ${DBComments}  Missing Vendor name or Order Date
            Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', '${DBComments}', '${PandaBotName}', '${start_time}')

		    #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', '${DBComments}')
		    ${countTabs}=  Get Element Count  (//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")]
            FOR  ${J}  IN RANGE  1  ${countTabs+1}
                Sleep  1
                Click Element When Visible  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")])[1]
            END
            sleep  1
            #making changes for giving back ownership_status
            run keyword and return status  Scroll Element Into View  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
            ${ow_st}  Run Keyword And Return Status   Wait Until Page Contains Element  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  5
            Run Keyword If  '${ow_st}'=='True'  Give back Owner ship  ${ticket_num}
            sleep  1
            Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  40
            Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
        END
    ELSE
        ${date} =  Get Current Date  result_format=datetime
        Set Local Variable  ${DBComments}  Order Data Against Order Code ${Order_Num} Unavailable
        Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', '${DBComments}', '${PandaBotName}', '${start_time}')

        #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', '${DBComments}')
        ${countTabs}=  Get Element Count  (//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")]
        FOR  ${J}  IN RANGE  1  ${countTabs+1}
            Sleep  1
            Click Element When Visible  ((//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ])[2]/../../..//*//div[contains(@class,"close slds-col--bump-left slds-p-left--none slds-p-right--none")])[1]
        END
        sleep  1
        #making changes for giving back ownership_status
        run keyword and return status  Scroll Element Into View  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]
        ${ow_st}  Run Keyword And Return Status   Wait Until Page Contains Element  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  5
        Run Keyword If  '${ow_st}'=='True'  Give back Owner ship  ${ticket_num}
        sleep  1
        Wait Until Page Contains Element    (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a  40
        Click Element When Visible  (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
    END


Close Previous Email tabs
    ${previous_emails_count}    Get WebElements    (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="To"]/../../div[1]/div/div/ul/li/emailui-pill/a/button
    ${email_legth}    get length    ${previous_emails_count}
    IF    ${email_legth} > 0
        FOR  ${j}  IN RANGE  1  ${email_legth+1}
            sleep    0.5
            Click Button    ((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//*[text()="To"]/../../div[1]/div/div/ul/li/emailui-pill/a/button)[${j}]
        END
    END

#Save Record To Excel
#	[Arguments]  ${contact_email}  ${tick_row_num}
#	@{row}        Create List  ${contact_email}  ${tick_row_num}
#    Append To List  ${rows}  ${row}
#	Open Workbook  ${HOME_Path}\\Email Trace.xlsx
#	Append Rows to Worksheet  ${rows}
#    Save Workbook  ${HOME_Path}\\Email Trace.xlsx

Close Case
    [Arguments]  ${ticket_num}
    Sleep  1
    # Execute JavaScript    window.scrollTo(0,600)
	Scroll Element By Xpath    //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]/../..
    sleep  1
    Set Global Variable    ${contact_email}    ${contact_email}
    run keyword and return status  Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[@title="Edit Case Owner"]  enter
    Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//*[contains(text(),'Status')]/../..//button
    Click Element When Visible  //div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//*[@title="Resolved"]
    Scroll Element By Xpath    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]
    sleep  1
    Click Element When Visible    (//div//span[contains(@class,"title slds-truncate") and contains(text(),"${ticket_num}") ]/ancestor::section[@aria-expanded="true"]//button[contains(text(),'Save')])[last()]  enter
	sleep  1.5
    ${error_status}  Run Keyword And Return Status  Wait Until Page Contains Element  //*[contains(@class,"genericError uiOutputText")]  10
    IF  '${error_status}'=='True'
        Log  Error while saving ticket
	    ${date} =  Get Current Date  result_format=datetime
		Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Failed While Closing The Case', '${PandaBotName}', '${start_time}')

        #Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Skipped', 'Failed While Closing The Case')
        Click Element  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")]//button[contains(@title,"Cancel")]
        sleep  1
        Wait Until Element Is Visible  //a[contains(@class,"tabHeader slds-context-bar__label-action")]/../div[2]  40
        ${CloseTabs}=  Get Element Count  //a[contains(@class,"tabHeader slds-context-bar__label-action")]/../div[2]
        FOR  ${tabsC}  IN RANGE  1  ${CloseTabs}+1
            Click Element When Visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action")]/../div[2])[${tabsC}]
        END
        Click Element When Visible   (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a
    ELSE
        Log  saved successfully
		${date} =  Get Current Date  result_format=datetime
        Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`, `panda_bot`,`ticket_start_date`) VALUES ('${ticket_num}', '${date}', 'Resolved', 'Ticket Closed Successfully', '${PandaBotName}', '${start_time}')

		#Query  INSERT IGNORE INTO foodpanda.honkong_tickets (`ticket`, `ticket_process_date`, `status`, `comment`) VALUES ('${ticket_num}', '${date}', 'Resolved', 'Ticket Closed Successfully')
        Sleep  0.5
		Execute JavaScript    window.scrollTo(50,0)
        sleep  0.5
        run keyword and return status  Scroll Element Into View  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${ticket_num}')]/../div[2])[1]
        run keyword and return status  Click Element When Visible  (//a[contains(@class,"tabHeader slds-context-bar__label-action" ) and contains(@title,'${ticket_num}')]/../div[2])[1]/button
        Click Element When Visible   (//section[contains(@class,"layoutContent stage panelSlide hasFixedFooter")])/div/div/div/div/div/div[2]/a

    END