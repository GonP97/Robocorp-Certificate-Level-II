# +
*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault




# +
*** Variables ***
#${url}  https://robotsparebinindustries.com/#/robot-order
#${file_url}     https://robotsparebinindustries.com/orders.csv
${browser}  chrome

${head}             id=head 
${body}             body
${legs}             xpath=/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
${address}          id=address
${btn_preview}      id=preview  
${btn_submit}       id=order
${btn_new_ordr}     id=order-another
${img_robot}        xpath=/html/body/div/div/div[1]/div/div[2]/div/div

# +
*** Keywords ***

Get Secret file
    ${secret}=    Get Secret    secret
    Log    ${secret}[link]

    [Return]   ${secret}[link] 

Open the robot order website
    ${url}=  Get Secret file
    # open browser     ${url}     ${browser}
    Open Available Browser  ${url}
Close the annoying modal
    Click Button  //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    
Get orders
    ${file_url}=  Collect url from user
    Download    ${file_url}  target_file=${CURDIR}${/}orders.csv     overwrite=True
    ${csv}=    Read table from CSV    orders.csv
    [Return]    ${csv}
    
Collect url from user
    Add heading             Extremy Intelligent Robot
    Add text input          link    label=Enter the order file link     placeholder=Order URL
    ${result}=              Run dialog
    [Return]                ${result.link}


Fill the form

    [Arguments]     ${thisrow}
    
    Select From List By Value    ${head}    ${thisrow}[Head]
    
    Select Radio Button     ${body}     ${thisrow}[Body]
    Input Text    ${legs}    ${thisrow}[Legs]
    Input Text    ${address}    ${thisrow}[Address]
    
    
Preview the robot
    Click Button    ${btn_preview}
    
Submit the order
    Wait Until Keyword Succeeds    5x    0.1 sec    Submit
    
    
Submit
    Click Button    ${btn_submit}
    Page Should Contain Element    id=receipt
    
Store the receipt as a PDF file
    [Arguments]     ${order_n}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}receipts${/}${order_n}.pdf
    Set Local Variable   ${pdf1}    ${CURDIR}${/}output${/}receipts${/}${order_n}.pdf
    [Return]     ${pdf1}
    
    
Take a screenshot of the robot
    [Arguments]     ${order_n}
    
    ${robot}=  Capture Element Screenshot   ${img_robot}    ${CURDIR}${/}output${/}prints${/}${order_n}.jpeg
    
    [Return]     ${robot}
    
    
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf2}
    Open Pdf    ${pdf2}
    
     ${files}=    Create List
    ...     ${pdf2}
    ...     ${screenshot}
    
    Add Files To PDF    ${files}    ${pdf2}
    
    Close Pdf   ${pdf2}
    
    
Go to order another robot
    Click Button    ${btn_new_ordr}
    
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    ${CURDIR}${/}output${/}receipts.zip

# +
*** Tasks ***



Order robots from RobotSpareBin Industries Inc
    Set Selenium Implicit Wait    2 seconds
    Open the robot order website
     ${orders}=    Get orders
     FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Submit the order
         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
     END
    Create a ZIP file of the receipts
    Close All Browsers
