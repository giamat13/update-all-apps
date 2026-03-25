import subprocess

# הגדרת הנתיב לקובץ שלך
file_path = "main.bat"

try:
    # הרצת הקובץ
    result = subprocess.run([file_path], check=True, text=True, capture_output=True)
    
    # הדפסת הפלט של ה-Batch (אם תרצה)
    print("Output:", result.stdout)
    
except subprocess.CalledProcessError as e:
    print(f"שגיאה בהרצת הקובץ: {e}")