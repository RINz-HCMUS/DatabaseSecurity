import tkinter as tk
from tkinter import messagebox
import pyodbc
import hashlib

# ========================== KẾT NỐI CƠ SỞ DỮ LIỆU ==========================

def get_connection():
    """Kết nối đến SQL Server"""
    try:
        conn = pyodbc.connect(
            "DRIVER={SQL Server};"
            "SERVER=localhost\\LABSQL;"
            "DATABASE=QLSVNhom;"
            "UID=sa;"
            "PWD=123456789"
        )
        return conn
    except Exception as e:
        print("Lỗi kết nối SQL Server:", e)
        return None

# ========================== XỬ LÝ ĐĂNG NHẬP ==========================

def login(username, password):
    """Kiểm tra đăng nhập nhân viên"""
    conn = get_connection()
    if conn is None:
        return None

    cursor = conn.cursor()

    # Mã hóa mật khẩu bằng SHA1
    hashed_password = hashlib.sha1(password.encode()).hexdigest()
    
    try:
        cursor.execute("EXEC SP_SEL_PUBLIC_NHANVIEN ?, ?", (username, password))
        row = cursor.fetchone()
        conn.close()

        if row:
            return {"manv": row[0], "hoten": row[1], "email": row[2], "luong": row[3]}
        else:
            return None
    except Exception as e:
        print("Lỗi đăng nhập:", e)
        return None

# ========================== GIAO DIỆN ĐĂNG NHẬP ==========================

def show_login():
    """Giao diện đăng nhập"""
    def attempt_login():
        username = username_entry.get()
        password = password_entry.get()

        user_data = login(username, password)
        if user_data:
            root.destroy()
            show_dashboard(user_data)
        else:
            messagebox.showerror("Lỗi", "Sai tài khoản hoặc mật khẩu!")

    root = tk.Tk()
    root.title("Đăng nhập hệ thống")

    tk.Label(root, text="Tên đăng nhập:").pack()
    username_entry = tk.Entry(root)
    username_entry.pack()

    tk.Label(root, text="Mật khẩu:").pack()
    password_entry = tk.Entry(root, show="*")
    password_entry.pack()

    login_button = tk.Button(root, text="Đăng nhập", command=attempt_login)
    login_button.pack()

    root.mainloop()

# ========================== DASHBOARD ==========================

def show_dashboard(user_data):
    """Bảng điều khiển chính"""
    root = tk.Tk()
    root.title("Hệ thống quản lý sinh viên")

    tk.Label(root, text=f"Xin chào, {user_data['hoten']}!", font=("Arial", 14)).pack()

    tk.Button(root, text="Quản lý lớp học", command=lambda: show_class_management(user_data)).pack()
    tk.Button(root, text="Quản lý sinh viên", command=lambda: show_student_management(user_data)).pack()
    tk.Button(root, text="Nhập điểm sinh viên", command=lambda: show_score_entry(user_data)).pack()

    root.mainloop()

# ========================== QUẢN LÝ LỚP HỌC ==========================

def show_class_management(user_data):
    """Hiển thị danh sách lớp học mà nhân viên quản lý"""
    root = tk.Toplevel()
    root.title("Quản lý lớp học")

    tk.Label(root, text="Danh sách lớp học:").pack()
    
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT MALOP, TENLOP FROM LOP WHERE MANV = ?", user_data['manv'])
    
    for row in cursor.fetchall():
        tk.Label(root, text=f"{row[0]} - {row[1]}").pack()
    
    conn.close()
    root.mainloop()

# ========================== QUẢN LÝ SINH VIÊN ==========================

def show_student_management(user_data):
    """Hiển thị danh sách sinh viên trong lớp mà nhân viên quản lý"""
    root = tk.Toplevel()
    root.title("Quản lý sinh viên")

    tk.Label(root, text="Danh sách sinh viên trong lớp:").pack()
    
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT MASV, HOTEN, NGAYSINH, DIACHI FROM SINHVIEN 
        WHERE MALOP IN (SELECT MALOP FROM LOP WHERE MANV = ?)
    """, user_data['manv'])
    
    for row in cursor.fetchall():
        tk.Label(root, text=f"{row[0]} - {row[1]} - {row[2]} - {row[3]}").pack()
    
    conn.close()
    root.mainloop()

# ========================== NHẬP ĐIỂM SINH VIÊN ==========================

def insert_score(masv, mahp, diem, manv):
    """Ghi điểm vào CSDL (mã hóa điểm bằng Public Key của nhân viên)"""
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("EXEC SP_INSERT_BANGDIEM ?, ?, ?, ?", (masv, mahp, diem, manv))
    conn.commit()
    conn.close()

def show_score_entry(user_data):
    """Giao diện nhập điểm sinh viên"""
    root = tk.Toplevel()
    root.title("Nhập điểm sinh viên")

    tk.Label(root, text="Mã sinh viên:").pack()
    masv_entry = tk.Entry(root)
    masv_entry.pack()

    tk.Label(root, text="Mã học phần:").pack()
    mahp_entry = tk.Entry(root)
    mahp_entry.pack()

    tk.Label(root, text="Điểm:").pack()
    diem_entry = tk.Entry(root)
    diem_entry.pack()

    def submit_score():
        masv = masv_entry.get()
        mahp = mahp_entry.get()
        diem = float(diem_entry.get())
        insert_score(masv, mahp, diem, user_data["manv"])
        tk.messagebox.showinfo("Thành công", "Điểm đã được lưu!")

    tk.Button(root, text="Lưu điểm", command=submit_score).pack()
    root.mainloop()

# ========================== CHẠY ỨNG DỤNG ==========================

if __name__ == "__main__":
    show_login()
