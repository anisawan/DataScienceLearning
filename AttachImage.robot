*** Variables ***
${image_path}     C://Users//Administrator//Desktop//tempImage.png
${Hero_URL}    https://foodpanda-asia.deliveryherocare.com/
${HEROTOTAL}   False
***Keywords***

 
Paste Body into mail template
    [Arguments]  ${image_path}
    Unselect Frame
    Select Frame  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]
    Select Frame  (//iframe)[1]
    ${emailSt}=  Run keyword and return status  Press Keys  //html/body/center/table/tbody   CTRL+a
    Unselect Frame
    sleep   1.5
    #Scroll Element By Xpath   (//div[contains(@class,"slds-show_inline-block uiMenu")]//div//div//div//a//div//div//span[1]//lightning-primitive-icon//*)[3] 
    Scroll Element By Xpath   (//div[@class="slds-grid emailuiEmailToolbarContainer"]//child::li[3]//a//lightning-primitive-icon//*[last()])[last()]
    FOR  ${I}  IN RANGE  1  5
        sleep  0.5s
        ${ST}=  Run Keyword And Return Status    Click Element    (//div[@class="slds-grid emailuiEmailToolbarContainer"]//child::li[3]//a//lightning-primitive-icon//*[last()])[1]
        #${ST1}=  Run Keyword And Return Status    Click Element    (//div[@class="slds-grid emailuiEmailToolbarContainer"]//child::li[3]//a//lightning-primitive-icon//*[last()])[2]
        #${ST2}=  Run Keyword And Return Status    Click Element    (//div[@class="slds-grid emailuiEmailToolbarContainer"]//child::li[3]//a//lightning-primitive-icon//*[last()])[last()]
        Exit FOr Loop If  ${ST}
        Press Keys  //div[contains(@class,"oneRecordHomeFlexipage2Wrapper")]   ARROW_DOWN 
    
    END
    #Press Keys  //div[contains(@class,"oneRecordHomeFlexipage2Wrapper")]   ARROW_DOWN 
    #Press Keys  //div[contains(@class,"oneRecordHomeFlexipage2Wrapper")]   ARROW_DOWN 
    #Press Keys  //div[contains(@class,"oneRecordHomeFlexipage2Wrapper")]   ARROW_DOWN 
    #Click Element    (//div[contains(@class,"slds-show_inline-block uiMenu")]//div//div//div//a//div//div//span[1]//lightning-primitive-icon//*)[3]
    Click Element When Visible  //li//a[contains(text(),"FP PS HK Wastage Notification Email Template")]
    sleep  5
    Select Frame  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]
    Select Frame  (//iframe)[1]
    #Copy Image to Clipboard  ${image_path}
    #sleep  2s
    #Click Element When Visible  (//html/body/center//div//center//table//tbody//tr)[1]//td  
    #Press Keys  None   BACKSPACE
    #Press Keys  None    CTRL+v
    #sleep  2
Get Table Row Data
    @{data}=    Create List
    ${columns}=    Get Element Count    //span[contains(text(),'Order Code')]//..//..//..//..//..//..//tr[2]/td
    FOR    ${index}    IN RANGE    1    ${columns + 1}
       ${cell_text}=    Get Text    //span[contains(text(),'Order Code')]//..//..//..//..//..//..//tr[2]/td[${index}]
       Append To List    ${data}    ${cell_text}
    END
    [Return]    ${data}
Test adding row
    ${data}=  Get Table Row Data
    set local variable  ${new_row_position}  3
    Execute Javascript    var table = document.querySelector('//span[contains(text(),'Order Code')]//..//..//..//..//..//..//tr[3]//..//..//..//table'); var row = table.insertRow(${new_row_position}); var cell; for(var i = 0; i < 4; i++){ cell = row.insertCell(i); cell.innerText = '${data}[i]';}
    .
Fill Data Into Template English
    [Arguments]  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total}   ${Count}
    #Select Frame  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]
    #Select Frame  (//iframe)[1]
    #Test Adding row
    #Wait until page contains element  //span[contains(text(),'Outlet Name：')]  30s
    #Execute JavaScript    document.evaluate("//span[contains(text(),'Outlet Name：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "Outlet Name:${OutletName}"
    #Execute JavaScript    document.evaluate("//span[contains(text(),'Order Date：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "Order Date:${OrderDate}"
    Execute JavaScript    document.evaluate("//span[contains(text(),'Order Code')]//..//..//..//..//..//..//..//tr[${Count}]//td[1]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${OrderCode}"
    sleep  0.2
    Execute JavaScript    document.evaluate("//span[contains(text(),'Order Code')]//..//..//..//..//..//..//..//tr[${Count}]//td[2]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${RemovedItem}"
    sleep  0.2
    Execute JavaScript    document.evaluate("//span[contains(text(),'Order Code')]//..//..//..//..//..//..//..//tr[${Count}]//td[3]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${IssueType}"
    sleep  0.2
    Execute JavaScript    document.evaluate("//span[contains(text(),'Order Code')]//..//..//..//..//..//..//..//tr[${Count}]//td[4]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${RemovedAmount}"
    sleep  0.2
    #Execute JavaScript    document.evaluate("(//span[contains(text(),'$')])[2]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${Total}"
Fill Data Into Template Other
    [Arguments]  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total}  ${Count}
    #Select Frame  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]
    #Select Frame  (//iframe)[1]
    #Wait until page contains element  //span[contains(text(),'\u9910\u5ef3\u540d\u7a31\uff1a')]   30s
    #Execute JavaScript    document.evaluate("//span[contains(text(),'餐廳名稱：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "餐廳名稱：${OutletName}"
    #Execute JavaScript    document.evaluate("//span[contains(text(),'訂單日期：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "訂單日期：${OrderDate}"
    Execute JavaScript    document.evaluate("//span[contains(text(),'訂單編號')]//..//..//..//..//..//..//..//tr[${Count}]//td[1]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${OrderCode}"
    sleep  0.2
    Execute JavaScript    document.evaluate("//span[contains(text(),'訂單編號')]//..//..//..//..//..//..//..//tr[${Count}]//td[2]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${RemovedItem}"
    sleep  0.2
    Execute JavaScript    document.evaluate("//span[contains(text(),'訂單編號')]//..//..//..//..//..//..//..//tr[${Count}]//td[3]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${IssueType}"
    sleep  0.2
    Execute JavaScript    document.evaluate("//span[contains(text(),'訂單編號')]//..//..//..//..//..//..//..//tr[${Count}]//td[4]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${RemovedAmount}"
    sleep  0.2
    
    #Execute JavaScript    document.evaluate("(//span[contains(text(),'$')])[1]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${Total}"

Attach images if Exists
    [Arguments]  ${ImagesPath}
    Unselect Frame
    ${directory_exists}=  Run kEyword And return status  Directory Should Exist    ${ImagesPath}
    IF    ${directory_exists}    
        Log  Directory Exists
        Compress Images If Limit Exceeded   ${ImagesPath}     22
        ${image_paths}=    OperatingSystem.List Files In Directory   ${ImagesPath} 
        
        FOR    ${img_path}    IN    @{image_paths}
            Log    ${ImagesPath}\\${img_path}
            Choose File    xpath=//input[contains(@id,"attachFileActionButtonInput")]    ${ImagesPath}\\${img_path}
            sleep  2s
        END
    ELSE    
        Log    Directory does not exist
    END
    
    
    
Copy Image to Clipboard
    [Arguments]  ${image_path}
    send_image_to_clipboard    ${image_path}

Email Formating
    Log  this is the key word in code where i will get the data
  
  
Login to Hero Portal
    FOR  ${I}  IN RANGE  1  5
        Execute javascript  window.open('','_blank')
        ${Windows} =	Get Window Handles
        Switch window  ${Windows}[1]
        goto    ${Hero_URL}
        ${Already_Login}  Run keyword and return status  Wait until page contains element  //li//child::span[@aria-label="folder-open"]  8s
        IF  '${Already_Login}' == 'False'
            ${Login_Page}  Run keyword and return status  Wait until page contains element  //input[@name="identifier"]  20s
            Input text when element is visible  //input[@name="identifier"]  ${sl_user_name} 
            Click element when visible  //input[@value="Next"]
            Input text when element is visible  //input[@type="password"]  ${sl_password}
            Click element when visible  //input[@value="Verify"]
            Run keyword and return status  Click element when visible  //a[@aria-label="Select Security Question."]
            Input text when element is visible  //input[@name="credentials.answer"]  panda
            Click element when visible  //input[@value="Verify"]
        END
        ${Login_Successful}  Run keyword and return status  Wait until page contains element  //li//child::span[@aria-label="folder-open"]  20s
        IF  '${Login_Successful}' == 'True' or '${Already_Login}' == 'True'
            Exit for loop
        ELSE
            Close window
            Switch window  ${Windows}[0]
        END
    END

Chat Down Arrow If Exist
    ${ArrowDown}  Get element count  //div[contains(@class,'messagePanel')]//span[@aria-label="down"]
    FOR  ${Arr}  IN RANGE  1  ${ArrowDown}+1
        Scroll Element By Xpath    (//div[contains(@class,'messagePanel')]//span[@aria-label="down"])[1]
        Click Element   (//div[contains(@class,'messagePanel')]//span[@aria-label="down"])[1]
        sleep  0.25s
    END
Download Image through Order ID
    [Arguments]  ${OrderId}  ${CcrName}  ${ImageOrderPath}  ${ticket_num}
    Wait until page contains element  //li//child::span[@aria-label="folder-open"]  20s
    Click element when visible  //li//child::span[@aria-label="folder-open"]
    Click element when visible  //div[@data-testid="search-select"]
    Click element when visible  //div[text()='Order ID']
    Input text when element is visible  //input[@data-testid="search-box"]  ${OrderId}
     
    Click element when visible  //button[contains(@class,"input-search-button")]
    sleep  5
    #Bot will check if chat not exists then click on active button
    ${CHeck_Row_Data}=  Does Page Contain Element  (//tr[contains(@class,'ant-table-row')])[1]
    IF  ${CHeck_Row_Data} == False
        Click button  //button[@data-testid="ticket-status-switch"]
        sleep  3s
    END
    #Iterating on Tables
    FOR  ${Page}  IN RANGE  1  50
        ${Ccr_Count}  Get element count  (//tr[contains(@class,'ant-table')]//td[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '${CcrName}')]//ancestor::tr//td[4][not(starts-with(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'rs-'))]//ancestor::tr/td[1]//a)
        ${N_Ccr_Count}  Get element count  (//tr[contains(@class,'ant-table')]//td[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '')]//ancestor::tr//td[4][not(starts-with(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'rs-'))]//ancestor::tr/td[1]//a)

        IF  ${Ccr_Count}>0
            ${ImageFlag}=  Download Image CCR Matched    ${ImageOrderPath}  ${OrderId}  ${CcrName}  ${Ccr_Count}
        ELSE IF  ${N_Ccr_Count}>0
            ${ImageFlag}=  Download Image CCR Matched    ${ImageOrderPath}  ${OrderId}  ${EMPTY}  ${N_Ccr_Count}
        ELSE
            Set Local Variable  ${ImageFlag}  False
            Run keyword and Return status   Set Screenshot Directory  C:\\Error_Screenshots
            ${current_time}=    Get Current Date    result_format=%Y-%m-%d-%H-%M-%S
            Run keyword and Return status   Capture Page Screenshot  ${ticket_num}_${OrderId}_${current_time}.png
        END
        Exit FOr Loop if   '${ImageFlag}'== 'True'
        ${TT}  Is Element Enabled   //button[contains(text(),'Next')]
        Log  ${TT}
        Exit for loop if  ${TT}!=True
        Click element when visible  //button[contains(text(),'Next')]
        sleep  1.5s
    END
    Close window
    ${Windows} =	Get Window Handles
    Switch window  ${Windows}[0]
    
Update Total Price 
	sleep  2s
	select frame  //iframe[@title="Mercury embed"]
    Wait Until Keyword Succeeds  3x  2s    Click element when visible  //div[@data-node-key="orders"]//div[@data-tab-name="orders"]
	Wait Until Keyword Succeeds  3x  2s    Click element when visible  //div[@data-node-key="order_invoice"]//div[@data-widget-name="order_invoice"]
	${Total}=  get text  (//*[@data-test-id="order-invoice-basket-value"]//span)[last()]
	log  ${Total}
	log  ${HEROTOTAL}
    Set Global Variable  ${HEROTOTAL}   ${Total}
	unselect frame    

Download Image CCR Matched    
    [Arguments]  ${ImageOrderPath}  ${OrderId}  ${CcrName}     ${Ccr_Count}
    Set Local Variable  ${ImageFlag}  False
    FOR  ${I}  IN RANGE  1  ${Ccr_Count}+1
        Click element when visible  (//tr[contains(@class,'ant-table')]//td[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '${CcrName}')]//ancestor::tr//td[4][not(starts-with(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'rs-'))]//ancestor::tr/td[1]//a)[${I}]
        sleep  3s
        ${Windows} =	Get Window Handles
        Switch window  ${Windows}[2]
        #Switch window  NEW
        Run keyword and return status  Chat Down Arrow If Exist  
        Run keyword and return status  Wait until page contains element  //a[contains(@href,'https://helpcenter')]  10s
        ${Total_Images}  Get element count  //a[contains(@href,'https://helpcenter')]
        Run Keyword and Return Status  Update Total Price  
        unselect frame 
        IF  ${Total_Images} > 0
            FOR  ${Img}  IN RANGE  1  ${Total_Images}+1
                Wait until page contains element  (//a[contains(@href,'https://helpcenter')])[${Img}]  20s
                Click element  (//a[contains(@href,'https://helpcenter')])[${Img}]
                ${Windows} =	Get Window Handles
                Switch window  ${Windows}[3]
                
                ${imageStatus}=  Run Keyword And Return Status  Wait until page contains element  //img  8s
                IF  ${imageStatus}
                    ${Image_Src}  Get element attribute  //img  src
                    OperatingSystem.Create directory  ${ImageOrderPath}\\${OrderId}
                    download_image_hero  ${Image_Src}  ${ImageOrderPath}\\${OrderId}\\${OrderId}${Img}.jpg
                    Set Local Variable  ${ImageFlag}  True
                END
                
                ${excludes} =	Get Window Handles
                IF  ${Total_Images} > 1
                    Close window
                    Switch window  ${excludes}[2]
                ELSE
                    Close window
                    Switch window  ${excludes}[2]
                END
            END
            Close window
            ${Windows} =	Get Window Handles
            #Switch window  MAIN
            Switch window  ${Windows}[1]
       ELSE
            Close window
            ${Windows} =	Get Window Handles
            Switch window  ${Windows}[1]
       END
       log  ${ImageFlag}=True
       Exit For Loop If  '${ImageFlag}' == 'True'
    END
    [Return]  ${ImageFlag}
    
Close All Tabs if open
    ${Windows} =	Get Window Handles
    ${TabLen}=  Get length  ${Windows}
    
    FOR  ${I}  IN RANGE  ${TabLen-1}  0  -1
        ${ck}=  Run Keyword And Return Status   Switch window  ${Windows}[${I}]
        IF  ${ck}
            Close window
            
        END
    END
    Switch window  ${Windows}[0]
    
Hero Portal work
    [Arguments]   ${OrderId}  ${CcrName}  ${ImageOrderPath}  ${ticket_num}
    FOR  ${I}  IN RANGE  1  3
        ${ST}=  Run Keyword And Ignore Error  Login to Hero portal and download the images if Exists  ${OrderId}  ${CcrName}  ${ImageOrderPath}  ${ticket_num}
        IF  '${ST}[0]' == 'FAIL'
            Close All Tabs if open
            Fail  Bot fail on Hero portal error is: ${ST}[1] 
        END
        Exit For Loop If  '${ST}[0]' == 'PASS'
        sleep  2s
    END
Login to Hero portal and download the images if Exists
    [Arguments]   ${OrderId}  ${CcrName}  ${ImageOrderPath}  ${ticket_num}
    Login to Hero Portal
    Download Image through Order ID  ${OrderId}  ${CcrName}  ${ImageOrderPath}  ${ticket_num}

Sales Force Add Template part
    [Arguments]  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total}  ${image_path}  ${ticket_num}   ${Issue_Type_cantonese}
    Paste Body into mail template  ${image_path}
    #Fill Data Into Template English  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total} 
    #Fill Data Into Template Other    ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total} 
    ${item_names}  ${item_prices}=     Extract Items And Prices    ${RemovedItem} 
    ${itemLn}=  Get length  ${item_names}
    Wait until page contains element  //span[contains(text(),'餐廳名稱：')]  30s
    
    FOR  ${I}  IN RANGE  1  ${itemLn}
        Execute Javascript    var xpath = "//span[contains(text(),'訂單編號')]//ancestor::table[1]"; var table = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; var row = table.insertRow(2); var cell; var style = "border-left:solid #d9d9d9 1pt;border-right:solid #d9d9d9 1pt;border-bottom:solid #d9d9d9 1pt;border-top:solid #d9d9d9 1pt;vertical-align:top;padding:5pt 5pt 5pt 5pt;overflow:hidden;overflow-wrap:break-word;"; for(var i = 0; i < 4; i++){ cell = row.insertCell(i); cell.textContent = ' '; cell.style.cssText = style; }
        sleep  1s
        
    END
    Execute JavaScript    document.evaluate("//span[contains(text(),'餐廳名稱：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "餐廳名稱：${OutletName}"
    sleep  0.2 
    Execute JavaScript    document.evaluate("//span[contains(text(),'訂單日期：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "訂單日期：${OrderDate}"
    sleep  0.2

    FOR  ${I}  IN RANGE  0  ${itemLn}
       
       Fill Data Into Template Other  ${OutletName}  ${OrderDate}  ${OrderCode}    ${item_names}[${I}]    ${Issue_Type_cantonese}   ${item_prices}[${I}]  ${Total}     ${I+2}
    END
    
    Execute JavaScript    document.evaluate("//span[contains(text(),'訂單編號')]//ancestor::table[1]//span[contains(text(),'$')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${Total}"

    FOR  ${I}  IN RANGE  1  ${itemLn}
      Execute Javascript    var xpath = "//span[contains(text(),'Order Code')]//ancestor::table[1]"; var table = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; var row = table.insertRow(2); var cell; var style = "border-left:solid #d9d9d9 1pt;border-right:solid #d9d9d9 1pt;border-bottom:solid #d9d9d9 1pt;border-top:solid #d9d9d9 1pt;vertical-align:top;padding:5pt 5pt 5pt 5pt;overflow:hidden;overflow-wrap:break-word;"; for(var i = 0; i < 4; i++){ cell = row.insertCell(i); cell.textContent = ' '; cell.style.cssText = style; }
       sleep  1s 
    END
    Execute JavaScript    document.evaluate("//span[contains(text(),'Outlet Name：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "Outlet Name：${OutletName}"
    Execute JavaScript    document.evaluate("//span[contains(text(),'Order Date：')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "Order Date：${OrderDate}"
    
    FOR  ${I}  IN RANGE  0  ${itemLn}
        
       Fill Data Into Template English  ${OutletName}  ${OrderDate}  ${OrderCode}    ${item_names}[${I}]    ${IssueType}   ${item_prices}[${I}]  ${Total}    ${I+2}
    END
    Execute JavaScript    document.evaluate("//span[contains(text(),'Order Code')]//ancestor::table[1]//span[contains(text(),'$')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${Total}"    
    sleep  1s
    #Click Element     
    ${Body_Text}  Get Text    //html/body/center
    OperatingSystem.Create File  C:\\Orders_Description\\${ticket_num}.txt    ${Body_Text} 
    #Run keyword and return status  Autosphere.Browser.Selenium.Press Keys  //html/body//center/table/tbody    CTRL+a
    #Set Screenshot Directory  C:\\Error_Screenshots
    #Capture Element Screenshot    (//span[contains(text(),'Order Code')]//ancestor::body)[last()]  mailbody_${ticket_num}_${OrderCode}.png
    


Extract Items And Prices
    [Arguments]    ${items}
    ${split_pattern}=    Set Variable    (?=\\b\\d+\\s+x)
    @{items_list}=    Evaluate    re.split(r'${split_pattern}', '${items}')    re
    @{cleaned_items_list}=    Create List
    @{ammountList}=    Create List
    FOR    ${item}    IN    @{items_list}
        ${trimmed_item}=    Strip String    ${item}
        ${trimmed_item}=    Replace String    ${trimmed_item}   , Topping(s):  ${EMPTY}
        ${trimmed_item}=    Replace String    ${trimmed_item}   Topping(s):  ${EMPTY}
        Run Keyword If    '${trimmed_item}' != ''    Append To List    ${cleaned_items_list}    ${trimmed_item}
        IF  '${trimmed_item}' != ''
            IF  'HKD' in '${trimmed_item}'
                ${price}=    Get Regexp Matches    ${trimmed_item}    HKD\\s*(\\d+\\.?\\d*)
                Append To List    ${ammountList}    ${price}[0]
            ELSE
                Append To List    ${ammountList}    ${EMPTY}
            END
            
        END
    END
    [Return]    ${cleaned_items_list}  ${ammountList}
Adding template and inserting required data into template
    [Arguments]  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total}  ${image_path}  ${ticket_num}  ${Issue_Type_cantonese}
	log  ${Total}
    Set Local Variable   ${FlowStatus}  False
    FOR  ${I}  IN RANGE  1  3
        ${ST}=  Run keyword and ignore error  Sales Force Add Template part  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total}  ${image_path}  ${ticket_num}  ${Issue_Type_cantonese}
        IF  '${ST}[0]' == 'FAIL'
            ${ck}=  Discard The template and try again
            IF  ${ck} == False
                Fail  Bot fail on Inserting template part and when bot tries to discard the mail it fails
            END
        ELSE
            Set Local Variable   ${FlowStatus}  True
        END
        Exit For Loop If  '${ST}[0]' == 'PASS'
        sleep  2s
    END
    [Return]  ${ST}
Discard The template and try again
    Unselect Frame
    Set Local Variable   ${FlowStatus}  False
    FOR  ${I}  IN RANGE  1  20
        ${ST}=  Run Keyword And Return Status    Click Element    (//div[contains(@data-buttontype,"delete")]//button//div//lightning-primitive-icon//*)[3]
        IF  ${ST}
            Click Element when visible  //button[@class="slds-button slds-button_brand"][contains(text(),'Discard')]
            Set Local Variable   ${FlowStatus}  True
            sleep  4s
        END
        Exit FOr Loop If   ${ST}
        Press Keys  //div[contains(@class,"oneRecordHomeFlexipage2Wrapper")]   ARROW_DOWN 
    
    END
    [Return]  ${FlowStatus}
Normalize String keyword
    [Arguments]    ${string}
    ${normalized_string}=    Replace String    ${string}    _    ${SPACE}
    ${normalized_string}=    Replace String    ${normalized_string}    -    ${SPACE}
    ${normalized_string}=    Convert To Lowercase    ${normalized_string}
    [Return]    ${normalized_string.strip()}    

Write Total of HeroCre Potal
    [Arguments]  ${Total}
	log  ${Total}
	log  ${HEROTOTAL}
    Unselect Frame
    Select Frame  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]
    Select Frame  (//iframe)[1]
	Execute JavaScript    document.evaluate("//span[contains(text(),'訂單編號')]//ancestor::table[1]//span[contains(text(),'${Total}')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${HEROTOTAL}"
    Execute JavaScript    document.evaluate("//span[contains(text(),'Order Code')]//ancestor::table[1]//span[contains(text(),'${Total}')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.textContent = "${HEROTOTAL}"
    #Run keyword and return status  Autosphere.Browser.Selenium.Press Keys  //html/body//center/table/tbody    CTRL+a 

press Ctrl a
    Unselect Frame
    Select Frame  (((//a[contains(@class,"tabHeader slds-context-bar__label-action")]/span[2])/ancestor::div//section[contains(@class,"tabContent active oneConsoleTab") and contains(@aria-expanded,"true")]/div[contains(@class,"oneWorkspace active hasFixedFooter navexWorkspace")])//iframe)[1]
    Select Frame  (//iframe)[1]
    Run keyword and return status  Autosphere.Browser.Selenium.Press Keys  //html/body//center/table/tbody    CTRL+a
    Run keyword and return status  Autosphere.Browser.Selenium.Press Keys  //html/body//center/table/tbody    ARROW_DOWN
    sleep  2s

Attached Foodpanda Temp CR
    #p8xn-9yk7
    [Arguments]  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total}  ${ticket_num}  ${Issue_Type_cantonese}
    # Set local variable  ${OutletName}  Shahid
    # Set local variable  ${OrderDate}  17/05/2024
    #Set local variable  ${OrderCode}  f1ds-g9ym
    # Set local variable  ${RemovedItem}  Pizza, Karhai, Or b Boht Koch
    #Set local variable  ${IssueType}  	Missing item
    # Set local variable  ${RemovedAmount}  PKR:300 
    # Set local variable  ${Total}  PKR:300
    ${IssueType}=  Normalize String keyword  ${IssueType}
    log  NAME_${IssueType}_END
	log  ${Total}
    Set local variable  ${AttachImagePath}  C:\\Attach Image Foodpanda\\Ordernumber
    sleep  2
    ${ST}=  Adding template and inserting required data into template  ${OutletName}  ${OrderDate}  ${OrderCode}  ${RemovedItem}  ${IssueType}  ${RemovedAmount}  ${Total}  ${image_path}  ${ticket_num}  ${Issue_Type_cantonese}
    IF  '${ST}[0]' == 'PASS'
        IF  '${IssueType}' != 'missing item'
            Hero Portal work  ${OrderCode}  ${IssueType}   ${AttachImagePath}  ${ticket_num}
			log  ${HEROTOTAL}
            IF  '${HEROTOTAL}' != 'False'
                Write Total of HeroCre Potal  ${Total}
            END
            Attach images if Exists  ${AttachImagePath.strip()}\\${OrderCode}
            Log   ${AttachImagePath}
            sleep  5s
            Run Keyword and return status  Wait until keyword succeeds  5  2s  OperatingSystem.Empty Directory   ${AttachImagePath.strip()}\\${OrderCode}
            Run Keyword and return status  Wait until keyword succeeds  5  2s  OperatingSystem.Remove Directory   ${AttachImagePath.strip()}\\${OrderCode}
        END
        press Ctrl a
    ELSE
        Fail  Bot Failed on adding template, error is : ${ST}[1]
    END
    



