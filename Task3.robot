*** Settings ***
Documentation    Sales Force Ticket Processing
Library          Autosphere.Browser.Selenium  run_on_failure=Nothing
Library          OperatingSystem
Library          Autosphere.Email.ImapSmtp
Library          copyImageFromDirectory.py
Library   		 String
Library   		 BuiltIn
Library   		 DateTime
Library   		 Autosphere.Database
Library   		 Autosphere.Desktop
Library   		 Autosphere.FileSystem
Library   		 Autosphere.Excel.Files
Library   		 Collections
Library   		 Process
Library          Autosphere.HTTP
Library          Autosphere.RobotLogListener
Library          PythonHandlerClass.py
Resource         AttachImage.robot
Resource         Main.robot
Test Teardown    Teardown Alerts

*** Variables ***
${sl_user_name}    panda.bot18.ext@foodpanda.com
${sl_password}     Automation@123456
${region_name}     FP PS HK Wastage Team (Bot 3)
${GO_TO_URL_QUEUE}      https://deliveryhero.lightning.force.com/lightning/o/Case/list?filterName=FP_PS_HK_Wastage_Team_Bot_3
${contact_email}
${translated_text}
${PandaBotName}   Panda Bot18
@{contact_email}
@{itemss}=
@{itemss_qan}=
${TicketID}
${ProcessTime}
${Status}
${TraceFile}  TraceFile.xlsx
${Comment}
@{itemss_price}=
${Order_Date}
${HOME_Path}  C:\\FP HK
${split_word}
${Task_Time}  60  #task execution timeout
${gmail_password_onv}  foodpandabot_18
${IMAP_HOST}         imap.gmail.com
${IMAP_PORT}         993
${APP_PASSWORD}      mxwp iqor vrfo bcqu  # Use the app password generated earlier
${alert_failure_count}     3
${region}   Hongkong
*** Tasks ***
FP PS HK Wastage Bot 18 Main Task
    Log  Queue Name: ${region_name}
    FP PS HK Wastage Bot 1

*** Keywords ***
Start Chrome Browser
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    Call Method    ${options}    add_argument   --remote-debugging-port\=9234
    Call Method    ${options}    add_argument   --user-data-dir\=\\Chrome_user_dir_18\\User Data 18\\Default
    Call Method    ${options}    add_argument   --profile-directory\=PandaBot18
    Open Browser  about:blank  Chrome  options=${options}
    Maximize Browser Window
