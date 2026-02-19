import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import keyring
import sys

def send_email(to_address, subject, body):
    # Create the email
    group_email = 'delivery.alerts@autosphere.ai'  # The group email address
    to_email = to_address  # The recipient's email address
    stored_email = keyring.get_password("exchange_email", "username")
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
        keyring.set_password("exchange_email", "username", username)
        keyring.set_password("exchange_password", username, password)

    msg = MIMEMultipart()
    msg['From'] = group_email
    msg['To'] = to_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    # Establish a secure SMTP connection to your Exchange server
    with smtplib.SMTP('smtp.office365.com', 587) as server:
        server.starttls()
        server.login(username, password)
        
        # Send the email
        server.sendmail(group_email, to_email, msg.as_string())

    print("Email sent successfully.")

if __name__ == "__main__":
    # If the script is run directly, prompt the user for the email content
    recipient = input("Enter recipient's email address: ")
    email_subject = input("Enter email subject: ")
    email_body = input("Enter email body: ")
    send_email(recipient, email_subject, email_body)