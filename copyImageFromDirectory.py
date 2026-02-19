from io import BytesIO
import win32clipboard
from PIL import Image
import os
import requests

class copyImageFromDirectory:
    def send_image_to_clipboard(self,filepath):
        image = Image.open(filepath)

        output = BytesIO()
        image.convert("RGB").save(output, "BMP")
        data = output.getvalue()[14:]
        output.close()

        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardData(win32clipboard.CF_DIB, data)
        win32clipboard.CloseClipboard()
        print("Image Copied")
        
    def compress_images_if_limit_exceeded(self,folder_path, target_size_mb):
        total_size = 0
        target_size_mb=int(target_size_mb)
        # Get all image files in the folder
        image_files = [os.path.join(folder_path, file) for file in os.listdir(folder_path) if file.endswith(('.jpg', '.jpeg', '.png'))]

        # Calculate total size of all images
        for file_path in image_files:
            total_size += os.path.getsize(file_path)

        # Check if total size exceeds the target size
        if total_size > target_size_mb * 1024 * 1024:
            # Calculate the compression ratio needed to achieve the target size
            compression_ratio = (target_size_mb * 1024 * 1024) / total_size

            # Compress each image individually
            for file_path in image_files:
                with Image.open(file_path) as img:
                    # Resize the image to reduce file size
                    new_width = int(img.width * compression_ratio)
                    new_height = int(img.height * compression_ratio)
                    resized_img = img.resize((new_width, new_height), Image.ANTIALIAS)

                    # Save the compressed image, overwriting the original file
                    resized_img.save(file_path)

            print('Images compressed successfully')
        else:
            print('Folder size is within the limit')
            
    def download_image_hero(self,url, filename):
        response = requests.get(url)
        if response.status_code == 200:
            with open(filename, 'wb') as f:
                f.write(response.content)
            print("Image downloaded successfully as", filename)
        else:
            print("Failed to download image:", response.status_code)
# filepath = "C://Users//Administrator//Desktop//tempImage.png"


# send_to_clipboard(filepath)
