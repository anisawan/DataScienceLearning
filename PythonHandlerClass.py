
import re
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import keyring
import sys
import os
import time
class PythonHandlerClass:
    def remove_emojis(self, text):
        text_without_emojis = re.compile(
            pattern="["
                    u"\U0001F000-\U0001F9FF"  # Miscellaneous Symbols and Pictographs
                    u"\U00002600-\U000027BF"  # Miscellaneous Symbols
                    u"\U0001F600-\U0001F64F"  # Emoticons
                    u"\U0001F300-\U0001F5FF"  # Miscellaneous Symbols and Arrows
                    u"\U0001F680-\U0001F6FF"  # Transport and Map Symbols
                    u"\U0001F700-\U0001F77F"  # Alchemical Symbols
                    u"\U0001F780-\U0001F7FF"  # Geometric Shapes Extended
                    u"\U0001F800-\U0001F8FF"  # Supplemental Arrows-C
                    u"\U0001F900-\U0001F9FF"  # Supplemental Symbols and Pictographs
                    u"\U0001FA00-\U0001FA6F"  # Chess Symbols
                    u"\U0001FA70-\U0001FAFF"  # Symbols and Pictographs Extended-A
                    r'\u20E3'
                    # u"\U0000200D\u200E\u200F\u2122\u2139\u2190-\u2199\u21A9-\u21AA\u231A\u2328\u23CF\u23E9\u23EA\u24C2-\u24FF\u25AA\u25AB\u25B6\u25C0-\u25FF\u2B00-\u2BFF\uE0000-\uE007F\uE0100-\uE01EF"
                    + "]+",
            flags=re.UNICODE,
        )
        matches = text_without_emojis.findall(text)

        if len(matches) > 0:
            print("Emojis are present")
            return text_without_emojis.sub(u'', text)
        else:
            print("No Emoji Found No Changes to the Text")
        # print(text_without_emojis)
        return text
    def send_email(self, subject, body, to_address , attachment_path=None):
        # The group email address
        group_email = 'delivery.alerts@autosphere.ai'
        
        # Convert to_address to a list if it's a comma-separated string
        to_emails = [email.strip() for email in to_address.split(',')]
        
        stored_email = keyring.get_password("exchange_email", "username_hassam")
        stored_password = keyring.get_password("exchange_password", stored_email if stored_email else "")

        if stored_email and stored_password:
            print("Using stored credentials.")
            username = stored_email
            password = stored_password
        else:
            # Prompt the user to enter their credentials
            username = input("Enter your Exchange email address: ")
            password = input("Enter your Exchange password: ")

            # Store the entered credentials securely
            keyring.set_password("exchange_email", "username_hassam", username)
            keyring.set_password("exchange_password", username, password)

        msg = MIMEMultipart()
        msg['From'] = group_email
        msg['To'] = ', '.join(to_emails)  # Set to_email for header display purposes
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        if attachment_path:
            try:
                filename = os.path.basename(attachment_path)  # Extract the filename from the path
                with open(attachment_path, "rb") as attachment:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(attachment.read())
                    encoders.encode_base64(part)
                    part.add_header('Content-Disposition', f"attachment; filename={filename}")
                    msg.attach(part)
            except FileNotFoundError:
                print(f"Error: Attachment file not found: {attachment_path}")

        # Establish a secure SMTP connection to your Exchange server
        with smtplib.SMTP('smtp.office365.com', 587) as server:
            server.starttls()
            server.login(username, password)
            
            # Send the email
            server.sendmail(group_email, to_emails, msg.as_string())  # Pass to_emails list to sendmail

        print("Email sent successfully.")

    def delete_old_files(self,directory, days=15):
      # Calculate the time threshold
      threshold = time.time() - days * 86400  # 86400 seconds in a day
      
      # Iterate through all files in the directory
      for filename in os.listdir(directory):
          file_path = os.path.join(directory, filename)
          
          # Check if it's a file
          if os.path.isfile(file_path):
              creation_time = os.path.getctime(file_path)
              
              # If the file is older than the threshold, delete it
              if creation_time < threshold:
                  #print(f"Deleting {filename} (Created on: {datetime.fromtimestamp(creation_time)})")
                  os.remove(file_path)