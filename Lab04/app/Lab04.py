import pyodbc 
import ttkbootstrap as ttk 
from ttkbootstrap.constants import *
from tkinter import messagebox, Toplevel 
import tkinter as tk
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
from Crypto.Protocol.KDF import PBKDF2
from Crypto.Cipher import AES
from Crypto.Util import Counter
from Crypto.Hash import SHA1

# =================== MÃ HOÁ ======================
# Hàm hỗ trợ mã hoá RSA 2048 bit
def make_randfunc(seed):
    # Khởi tạo bộ đếm và AES cipher một lần
    ctr = Counter.new(128, initial_value=0)
    cipher = AES.new(seed, AES.MODE_CTR, counter=ctr)
    
    def randfunc(n):
        # Dùng cipher hiện tại để tạo n byte ngẫu nhiên
        return cipher.encrypt(b'\x00' * n)
    
    return randfunc

# Hàm tạo cặp khóa RSA từ mật khẩu
def deterministic_rsa_keygen(password: str, salt: bytes = b'static salt'):
    # Lấy seed cố định 16 byte từ password sử dụng PBKDF2 
    seed = PBKDF2(password, salt, dkLen=16, count=500000, hmac_hash_module=SHA1)
    
    # Khởi tạo randfunc một lần sử dụng seed đã tạo
    randfunc = make_randfunc(seed)
    # Tạo khóa RSA sử dụng randfunc hiệu quả
    # Để tránh gọi lặp lại AES CTR mode cho mỗi byte ngẫu nhiên
    key = RSA.generate(2048, randfunc=randfunc)

    return key

# =================== KẾT NỐI SQL SERVER ======================
DB_CONFIG = {
    "driver": "{SQL Server}",
    "server": "localhost\\LABSQL",
    "database": "QLSVNhom",
    "uid": "sa",
    "pwd": "123456789"
}

# Lưu thông tin nhân viên đăng nhập
current_manv = None 
current_hoten = None 
current_mail = None 
current_luong = None
current_password = None  # Lưu mật khẩu của nhân viên đăng nhập
current_pubkey = None
curent_private_key = None

# Hàm kết nối SQL Server
def connect_db():
    try:
        conn = pyodbc.connect(
            f"DRIVER={DB_CONFIG['driver']};"
            f"SERVER={DB_CONFIG['server']};"
            f"DATABASE={DB_CONFIG['database']};"
            f"UID={DB_CONFIG['uid']};"
            f"PWD={DB_CONFIG['pwd']};"
        )
        return conn
    except Exception as e:
        messagebox.showerror("Lỗi kết nối", f"Không thể kết nối SQL Server: {e}")
        return None

# Kích thước giao diện
window_size = "1280x720"
query_size = "680x600"

# =================== GIAO DIỆN ĐĂNG NHẬP ======================
def login():
    global current_manv, current_pubkey, curent_private_key, current_password

    manv = entry_username.get()
    password = entry_password.get()
    # hash to VARBINARY
    # current_password = hashlib.sha1(password.encode('utf-8')).digest()
    current_password = SHA1.new(bytes(password, 'utf-16le')).digest()

    conn = connect_db()
    if not conn:
        return

    cursor = conn.cursor()
    print(f"MANV: {manv}\nPASSWORD: {current_password}\n")
    # So sánh mật khẩu sau khi băm (SHA1)
    cursor.execute("SELECT MANV, PUBKEY FROM NHANVIEN WHERE MANV = ? AND MATKHAU = ?", (manv, current_password))
    result = cursor.fetchone()
    conn.close()

    if result:
        current_manv = result[0]
        # ===========
        # I'M CHECKING HERE
        key = deterministic_rsa_keygen(password)
        curent_private_key = key
        current_pubkey = key.public_key()
        # ===========
        # current_pubkey = result[1]
        # ===========
        get_info_() # Lấy thông tin nhân viên đăng nhập
        # ===========
        messagebox.showinfo("Đăng nhập thành công", f"Xin chào nhân viên {current_manv}")
        open_main_window()
    else:
        messagebox.showerror("Lỗi", "Tên đăng nhập hoặc mật khẩu không đúng!")

# Hàm lấy thông tin nhân viên vừa đăng nhập
def get_info_():
    global current_hoten, current_mail, current_luong
    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN ?, ?", (current_manv, current_password))
        row = cursor.fetchone()
        if row:
            current_hoten = row[1]
            current_mail = row[2]
            current_luong = row[3] # Lương đã mã hóa bằng RSA
        conn.close()

    # Giải mã lương
    current_luong = PKCS1_OAEP.new(curent_private_key).decrypt(current_luong).decode('utf-8')

# =================== GIAO DIỆN ĐĂNG KÝ ======================
def register():
    reg_win = Toplevel()
    reg_win.title("Đăng ký Nhân viên")
    reg_win.geometry(query_size)

    # Nhãn và Entry cho các trường nhập liệu
    ttk.Label(reg_win, text="Mã nhân viên:").grid(row=0, column=0, padx=10, pady=10, sticky="w")
    manv_entry = ttk.Entry(reg_win)
    manv_entry.grid(row=0, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(reg_win, text="Họ tên:").grid(row=1, column=0, padx=10, pady=10, sticky="w")
    hoten_entry = ttk.Entry(reg_win)
    hoten_entry.grid(row=1, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(reg_win, text="Email:").grid(row=2, column=0, padx=10, pady=10, sticky="w")
    email_entry = ttk.Entry(reg_win)
    email_entry.grid(row=2, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(reg_win, text="Lương cơ bản:").grid(row=3, column=0, padx=10, pady=10, sticky="w")
    luong_entry = ttk.Entry(reg_win)
    luong_entry.grid(row=3, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(reg_win, text="Tên đăng nhập:").grid(row=4, column=0, padx=10, pady=10, sticky="w")
    tendn_entry = ttk.Entry(reg_win)
    tendn_entry.grid(row=4, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(reg_win, text="Mật khẩu:").grid(row=5, column=0, padx=10, pady=10, sticky="w")
    password_entry = ttk.Entry(reg_win, show="*")
    password_entry.grid(row=5, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(reg_win, text="Xác nhận mật khẩu:").grid(row=6, column=0, padx=10, pady=10, sticky="w")
    confirm_entry = ttk.Entry(reg_win, show="*")
    confirm_entry.grid(row=6, column=1, padx=10, pady=10, sticky="ew")

    reg_win.columnconfigure(1, weight=1)

    def do_register():
        manv = manv_entry.get().strip()
        hoten = hoten_entry.get().strip()
        email = email_entry.get().strip()
        luong = luong_entry.get().strip()
        tendn = tendn_entry.get().strip()
        password = password_entry.get().strip()
        confirm = confirm_entry.get().strip()

        # Kiểm tra dữ liệu nhập
        if not manv or not hoten or not email or not luong or not tendn or not password or not confirm:
            messagebox.showwarning("Chú ý", "Vui lòng điền đầy đủ thông tin!")
            return
        if password != confirm:
            messagebox.showwarning("Chú ý", "Mật khẩu không khớp!")
            return

        try:
            # Sinh cặp khóa RSA từ mật khẩu đã nhập
            key = deterministic_rsa_keygen(password)

            # Tạo phiên bản public key ngắn: sử dụng 20 ký tự đầu của SHA1(bản PEM của public key)
            full_pub = key.publickey().export_key(format='PEM')
            pub_hash = SHA1.new(full_pub).hexdigest()[:20]

            # Mã hoá mật khẩu với SHA1 (theo chuẩn đăng nhập)
            hashed_password = SHA1.new(bytes(password, 'utf-16le')).digest()

            # Mã hoá lương cơ bản sử dụng RSA (giả sử luong là chuỗi số)
            cipher_rsa = PKCS1_OAEP.new(key.publickey())
            encrypted_luong = cipher_rsa.encrypt(luong.encode('utf-8'))

            # Kết nối tới SQL Server và gọi stored procedure
            conn = connect_db()
            if not conn:
                return
            cursor = conn.cursor()
            cursor.execute("""
                EXEC SP_INS_PUBLIC_NHANVIEN ?, ?, ?, ?, ?, ?, ?
            """, (manv, hoten, email, encrypted_luong, tendn, hashed_password, pub_hash))
            conn.commit()
            messagebox.showinfo("Thành công", "Đăng ký nhân viên thành công!")
            reg_win.destroy()
        except Exception as e:
            messagebox.showerror("Lỗi", f"Không thể đăng ký nhân viên: {e}")

    ttk.Button(reg_win, text="Đăng ký", command=do_register, bootstyle="primary").grid(row=7, column=0, columnspan=2, pady=20)


# =================== GIAO DIỆN CHÍNH ======================
def open_main_window():
    login_register_window.destroy()
    main_window = ttk.Window(themename="cosmo")
    main_window.title(f"Quản lý Nhân viên - {current_manv}")
    main_window.geometry(window_size)

    main_frame = ttk.Frame(main_window)
    main_frame.pack(fill="both", expand=True, padx=10, pady=10)

    ttk.Label(main_frame, text=f"Xin chào Nhân viên {current_manv}", font=("Arial", 16, "bold")).grid(row=0, column=0, columnspan=2, pady=20)
    ttk.Button(main_frame, text="Quản lý Lớp học", command=manage_classes, bootstyle="primary").grid(row=1, column=0, padx=10, pady=5, sticky="ew")
    ttk.Button(main_frame, text="Quản lý Sinh viên", command=manage_students, bootstyle="info").grid(row=1, column=1, padx=10, pady=5, sticky="ew")
    ttk.Button(main_frame, text="Quản lý Bảng điểm", command=manage_grades, bootstyle="success").grid(row=2, column=0, padx=10, pady=5, sticky="ew")
    ttk.Button(main_frame, text="Quản lý Nhân viên", command=manage_employee, bootstyle="warning").grid(row=2, column=1, padx=10, pady=5, sticky="ew")
    ttk.Button(main_frame, text="Thoát", command=main_window.destroy, bootstyle="danger").grid(row=3, column=0, columnspan=2, pady=20, sticky="ew")

    main_frame.columnconfigure(0, weight=1)
    main_frame.columnconfigure(1, weight=1)

    main_window.mainloop()

# =================== QUẢN LÝ LỚP HỌC ======================
def manage_classes():
    class_win = Toplevel()
    class_win.title("Quản lý Lớp học")
    class_win.geometry(window_size)

    # Frame chứa treeview
    frame = ttk.Frame(class_win)
    frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
    class_win.rowconfigure(0, weight=1)
    class_win.columnconfigure(0, weight=1)

    columns = ("Mã lớp", "Tên lớp")
    tree = ttk.Treeview(frame, columns=columns, show="headings")
    for col in columns:
        tree.heading(col, text=col)
    tree.grid(row=0, column=0, sticky="nsew")
    frame.rowconfigure(0, weight=1)
    frame.columnconfigure(0, weight=1)

    # Nạp dữ liệu lớp của nhân viên đang đăng nhập
    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT MALOP, TENLOP FROM LOP WHERE MANV = ?", (current_manv,))
        for row in cursor.fetchall():
            tree.insert("", "end", values=(row[0], row[1]))
        conn.close()

    # Frame chứa nút thao tác
    btn_frame = ttk.Frame(class_win)
    btn_frame.grid(row=1, column=0, sticky="ew", padx=10, pady=5)
    btn_frame.columnconfigure((0,1,2), weight=1)

    def get_selected_class():
        sel = tree.focus()
        if not sel:
            messagebox.showwarning("Chú ý", "Vui lòng chọn lớp cần thao tác!")
            return None
        return tree.item(sel, "values")

    def view_students():
        sel = get_selected_class()
        if sel:
            malop = sel[0]
            view_class_students(malop)

    def edit_class_action():
        sel = get_selected_class()
        if sel:
            malop = sel[0]
            edit_class(malop)

    ttk.Button(btn_frame, text="View Students", command=view_students, bootstyle="info").grid(row=0, column=0, padx=5)
    ttk.Button(btn_frame, text="Edit Class", command=edit_class_action, bootstyle="warning").grid(row=0, column=1, padx=5)
    ttk.Button(btn_frame, text="Add New Class", command=add_class, bootstyle="success").grid(row=0, column=2, padx=5)

def view_class_students(malop):
    win = Toplevel()
    win.title(f"DS Sinh viên của lớp {malop}")
    win.geometry(window_size)

    frame = ttk.Frame(win)
    frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
    win.rowconfigure(0, weight=1)
    win.columnconfigure(0, weight=1)

    columns = ("Mã SV", "Họ Tên", "Ngày sinh", "Địa chỉ")
    tree = ttk.Treeview(frame, columns=columns, show="headings")
    for col in columns:
        tree.heading(col, text=col)
    tree.grid(row=0, column=0, sticky="nsew")
    frame.rowconfigure(0, weight=1)
    frame.columnconfigure(0, weight=1)

    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT MASV, HOTEN, CONVERT(varchar, NGAYSINH, 23), DIACHI FROM SINHVIEN WHERE MALOP = ?", (malop,))
        for row in cursor.fetchall():
            tree.insert("", "end", values=(row[0], row[1], row[2], row[3]))
        conn.close()

def edit_class(malop):
    # Mở cửa sổ chỉnh sửa thông tin lớp
    win = Toplevel() 
    win.title(f"Chỉnh sửa lớp {malop}")
    win.geometry(query_size)

    ttk.Label(win, text="Tên lớp:").grid(row=0, column=0, padx=10, pady=10, sticky="w")
    tenlop_entry = ttk.Entry(win)
    tenlop_entry.grid(row=0, column=1, padx=10, pady=10, sticky="ew")
    win.columnconfigure(1, weight=1)

    # Nạp thông tin lớp hiện tại
    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT TENLOP FROM LOP WHERE MALOP = ?", (malop,))
        row = cursor.fetchone()
        if row:
            tenlop_entry.insert(0, row[0])
        conn.close()

    def update_class():
        new_tenlop = tenlop_entry.get().strip()
        if not new_tenlop:
            messagebox.showwarning("Chú ý", "Tên lớp không được để trống!")
            return
        conn = connect_db()
        if conn:
            cursor = conn.cursor()
            cursor.execute("UPDATE LOP SET TENLOP = ? WHERE MALOP = ?", (new_tenlop, malop))
            conn.commit()
            conn.close()
            messagebox.showinfo("Thành công", "Cập nhật thông tin lớp thành công!")
            win.destroy()

    def delete_class():
        # Kiểm tra xem lớp có sinh viên không
        conn = connect_db()
        if conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM SINHVIEN WHERE MALOP = ?", (malop,))
            count = cursor.fetchone()[0]
            if count > 0:
                messagebox.showerror("Lỗi", "Không thể xoá lớp đã có sinh viên!")
            else:
                if messagebox.askyesno("Xác nhận", "Bạn có chắc muốn xoá lớp này không?"):
                    cursor.execute("DELETE FROM LOP WHERE MALOP = ?", (malop,))
                    conn.commit()
                    messagebox.showinfo("Thành công", "Đã xoá lớp!")
                    win.destroy()
            conn.close()

    btn_frame = ttk.Frame(win)
    btn_frame.grid(row=1, column=0, columnspan=2, pady=10)
    ttk.Button(btn_frame, text="Cập nhật", command=update_class, bootstyle="primary").grid(row=0, column=0, padx=5)
    ttk.Button(btn_frame, text="Xoá lớp", command=delete_class, bootstyle="danger").grid(row=0, column=1, padx=5)

def add_class():
    win = Toplevel()
    win.title("Thêm lớp mới")
    win.geometry(query_size)

    ttk.Label(win, text="Mã lớp:").grid(row=0, column=0, padx=10, pady=10, sticky="w")
    malop_entry = ttk.Entry(win)
    malop_entry.grid(row=0, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Tên lớp:").grid(row=1, column=0, padx=10, pady=10, sticky="w")
    tenlop_entry = ttk.Entry(win)
    tenlop_entry.grid(row=1, column=1, padx=10, pady=10, sticky="ew")
    win.columnconfigure(1, weight=1)

    def add_new():
        malop = malop_entry.get().strip()
        tenlop = tenlop_entry.get().strip()
        if not malop or not tenlop:
            messagebox.showwarning("Chú ý", "Vui lòng điền đầy đủ thông tin!")
            return
        conn = connect_db()
        if conn:
            cursor = conn.cursor()
            try:
                cursor.execute("INSERT INTO LOP (MALOP, TENLOP, MANV) VALUES (?, ?, ?)", (malop, tenlop, current_manv))
                conn.commit()
                messagebox.showinfo("Thành công", "Thêm lớp mới thành công!")
                win.destroy()
            except Exception as e:
                messagebox.showerror("Lỗi", f"Không thể thêm lớp: {e}")
            conn.close()

    ttk.Button(win, text="Thêm lớp", command=add_new, bootstyle="success").grid(row=2, column=0, columnspan=2, pady=10)

# =================== QUẢN LÝ SINH VIÊN ======================
def manage_students():
    student_win = Toplevel()
    student_win.title("Quản lý Sinh viên")
    student_win.geometry(window_size)

    # Frame chứa treeview hiển thị các lớp mà nhân viên quản lý
    frame = ttk.Frame(student_win)
    frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
    student_win.rowconfigure(0, weight=1)
    student_win.columnconfigure(0, weight=1)

    columns = ("Mã lớp", "Tên lớp")
    tree = ttk.Treeview(frame, columns=columns, show="headings")
    for col in columns:
        tree.heading(col, text=col)
    tree.grid(row=0, column=0, sticky="nsew")
    frame.rowconfigure(0, weight=1)
    frame.columnconfigure(0, weight=1)

    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT MALOP, TENLOP FROM LOP WHERE MANV = ?", (current_manv,))
        for row in cursor.fetchall():
            tree.insert("", "end", values=(row[0], row[1]))
        conn.close()

    btn_frame = ttk.Frame(student_win)
    btn_frame.grid(row=1, column=0, sticky="ew", padx=10, pady=5)
    btn_frame.columnconfigure((0,1,2), weight=1)

    def get_selected_class():
        sel = tree.focus()
        if not sel:
            messagebox.showwarning("Chú ý", "Vui lòng chọn lớp!")
            return None
        return tree.item(sel, "values")

    def view_students_of_selected_class():
        sel = get_selected_class()
        if sel:
            malop = sel[0]
            view_students_of_class(malop)

    ttk.Button(btn_frame, text="View Students", command=view_students_of_selected_class, bootstyle="info").grid(row=0, column=0, padx=5)
    ttk.Button(btn_frame, text="Add New Student", command=lambda: add_student(), bootstyle="success").grid(row=0, column=1, padx=5)

def view_students_of_class(malop):
    win = Toplevel()
    win.title(f"DS Sinh viên của lớp {malop}")
    win.geometry(window_size)

    frame = ttk.Frame(win)
    frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
    win.rowconfigure(0, weight=1)
    win.columnconfigure(0, weight=1)

    columns = ("Mã SV", "Họ Tên", "Ngày sinh", "Địa chỉ")
    tree = ttk.Treeview(frame, columns=columns, show="headings")
    for col in columns:
        tree.heading(col, text=col)
    tree.grid(row=0, column=0, sticky="nsew")
    frame.rowconfigure(0, weight=1)
    frame.columnconfigure(0, weight=1)

    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT MASV, HOTEN, CONVERT(varchar, NGAYSINH, 23), DIACHI FROM SINHVIEN WHERE MALOP = ?", (malop,))
        for row in cursor.fetchall():
            tree.insert("", "end", values=(row[0], row[1], row[2], row[3]))
        conn.close()

    btn_frame = ttk.Frame(win)
    btn_frame.grid(row=1, column=0, sticky="ew", padx=10, pady=5)
    btn_frame.columnconfigure((0,1), weight=1)

    def get_selected_student():
        sel = tree.focus()
        if not sel:
            messagebox.showwarning("Chú ý", "Vui lòng chọn sinh viên!")
            return None
        return tree.item(sel, "values")

    def edit_student_action():
        sel = get_selected_student()
        if sel:
            masv = sel[0]
            edit_student(masv)

    ttk.Button(btn_frame, text="Edit Student", command=edit_student_action, bootstyle="warning").grid(row=0, column=0, padx=5)
    ttk.Button(btn_frame, text="Add New Student", command=lambda: add_student(malop), bootstyle="success").grid(row=0, column=1, padx=5)

def edit_student(masv):
    win = Toplevel()
    win.title(f"Chỉnh sửa sinh viên {masv}")
    win.geometry(query_size)

    # Lấy thông tin sinh viên
    conn = connect_db()
    if not conn:
        return
    cursor = conn.cursor()
    cursor.execute("SELECT HOTEN, CONVERT(varchar, NGAYSINH, 23), DIACHI, MALOP FROM SINHVIEN WHERE MASV = ?", (masv,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        messagebox.showerror("Lỗi", "Không tìm thấy sinh viên!")
        return

    ttk.Label(win, text="Họ Tên:").grid(row=0, column=0, padx=10, pady=10, sticky="w")
    name_entry = ttk.Entry(win)
    name_entry.insert(0, row[0])
    name_entry.grid(row=0, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Ngày sinh (YYYY-MM-DD):").grid(row=1, column=0, padx=10, pady=10, sticky="w")
    dob_entry = ttk.Entry(win)
    dob_entry.insert(0, row[1])
    dob_entry.grid(row=1, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Địa chỉ:").grid(row=2, column=0, padx=10, pady=10, sticky="w")
    address_entry = ttk.Entry(win)
    address_entry.insert(0, row[2])
    address_entry.grid(row=2, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Mã Lớp:").grid(row=3, column=0, padx=10, pady=10, sticky="w")
    class_entry = ttk.Entry(win)
    class_entry.insert(0, row[3])
    class_entry.grid(row=3, column=1, padx=10, pady=10, sticky="ew")

    win.columnconfigure(1, weight=1)

    def update_student():
        new_name = name_entry.get().strip()
        new_dob = dob_entry.get().strip()
        new_address = address_entry.get().strip()
        new_class = class_entry.get().strip()
        if not new_name or not new_dob or not new_address or not new_class:
            messagebox.showwarning("Chú ý", "Vui lòng điền đầy đủ thông tin!")
            return
        conn = connect_db()
        if conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE SINHVIEN
                SET HOTEN = ?, NGAYSINH = ?, DIACHI = ?, MALOP = ?
                WHERE MASV = ?
            """, (new_name, new_dob, new_address, new_class, masv))
            conn.commit()
            conn.close()
            messagebox.showinfo("Thành công", "Cập nhật sinh viên thành công!")
            win.destroy()

    ttk.Button(win, text="Cập nhật", command=update_student, bootstyle="primary").grid(row=4, column=0, columnspan=2, pady=10)

def add_student(default_class=None):
    win = Toplevel()
    win.title("Thêm sinh viên mới")
    win.geometry(query_size)

    ttk.Label(win, text="Mã SV:").grid(row=0, column=0, padx=10, pady=10, sticky="w")
    masv_entry = ttk.Entry(win)
    masv_entry.grid(row=0, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Họ Tên:").grid(row=1, column=0, padx=10, pady=10, sticky="w")
    name_entry = ttk.Entry(win)
    name_entry.grid(row=1, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Ngày sinh (YYYY-MM-DD):").grid(row=2, column=0, padx=10, pady=10, sticky="w")
    dob_entry = ttk.Entry(win)
    dob_entry.grid(row=2, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Địa chỉ:").grid(row=3, column=0, padx=10, pady=10, sticky="w")
    address_entry = ttk.Entry(win)
    address_entry.grid(row=3, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Mã Lớp:").grid(row=4, column=0, padx=10, pady=10, sticky="w")
    class_entry = ttk.Entry(win)
    if default_class:
        class_entry.insert(0, default_class)
    class_entry.grid(row=4, column=1, padx=10, pady=10, sticky="ew")

    win.columnconfigure(1, weight=1)

    def add_new_student():
        masv = masv_entry.get().strip()
        name = name_entry.get().strip()
        dob = dob_entry.get().strip()
        address = address_entry.get().strip()
        malop = class_entry.get().strip()
        if not masv or not name or not dob or not address or not malop:
            messagebox.showwarning("Chú ý", "Vui lòng điền đầy đủ thông tin!")
            return
        conn = connect_db()
        if conn:
            cursor = conn.cursor()
            try:
                # Giả sử mật khẩu khởi tạo là '123456' và được mã hóa SHA1
                cursor.execute("""
                    INSERT INTO SINHVIEN (MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU)
                    VALUES (?, ?, ?, ?, ?, ?, HASHBYTES('SHA1', ?))
                """, (masv, name, dob, address, malop, masv, '123456'))
                conn.commit()
                messagebox.showinfo("Thành công", "Thêm sinh viên thành công!")
                win.destroy()
            except Exception as e:
                messagebox.showerror("Lỗi", f"Không thể thêm sinh viên: {e}")
            conn.close()

    ttk.Button(win, text="Thêm sinh viên", command=add_new_student, bootstyle="success").grid(row=5, column=0, columnspan=2, pady=10)

# =================== QUẢN LÝ BẢNG ĐIỂM ======================
def manage_grades():
    grade_win = Toplevel()
    grade_win.title("Quản lý Bảng điểm")
    grade_win.geometry(window_size)

    frame = ttk.Frame(grade_win)
    frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
    grade_win.rowconfigure(0, weight=1)
    grade_win.columnconfigure(0, weight=1)

    columns = ("Mã SV", "Họ Tên", "Mã HP", "Tên HP", "Điểm")
    tree = ttk.Treeview(frame, columns=columns, show="headings")
    for col in columns:
        tree.heading(col, text=col)
    tree.grid(row=0, column=0, sticky="nsew")
    frame.rowconfigure(0, weight=1)
    frame.columnconfigure(0, weight=1)

    # Gọi stored procedure SP_SEL_PUBLIC_BANGDIEM với current_manv và current_password
    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        try:
            cursor.execute("EXEC SP_SEL_PUBLIC_ENCRYPT_BANGDIEM ?", current_manv)
            # ====================
            # I'M CHECKING HERE
            rows = cursor.fetchall()
            cipher = PKCS1_OAEP.new(curent_private_key)
            for row in rows:
                print(f"PUBLIC KEY: {current_pubkey}")
                try:
                    decrypted_grade = cipher.decrypt(row[4]).decode('utf-8')
                except:
                    decrypted_grade = "Lỗi giải mã"
            # for row in cursor.fetchall():
                tree.insert("", "end", values=(row[0],row[1],row[2],row[3], decrypted_grade))
            # =====================
        except Exception as e:
            messagebox.showerror("Lỗi", f"Không thể truy vấn bảng điểm: {e}")
        conn.close()

    btn_frame = ttk.Frame(grade_win)
    btn_frame.grid(row=1, column=0, sticky="ew", padx=10, pady=5)
    btn_frame.columnconfigure((0,1,2), weight=1)

    def get_selected_grade():
        sel = tree.focus()
        if not sel:
            messagebox.showwarning("Chú ý", "Vui lòng chọn bản ghi cần thao tác!")
            return None
        return tree.item(sel, "values")

    def edit_grade_action():
        sel = get_selected_grade()
        if sel:
            edit_grade(sel)

    def delete_grade_action():
        sel = get_selected_grade()
        if sel:
            delete_grade(sel)

    ttk.Button(btn_frame, text="Edit Grade", command=edit_grade_action, bootstyle="warning").grid(row=0, column=0, padx=5)
    ttk.Button(btn_frame, text="Delete Grade", command=delete_grade_action, bootstyle="danger").grid(row=0, column=1, padx=5)
    ttk.Button(btn_frame, text="Add New Grade", command=add_grade, bootstyle="success").grid(row=0, column=2, padx=5)

def edit_grade(record):
    global current_manv
    # record: (MASV, HOTEN, MAHP, TENHP, DIEM)
    win = Toplevel()
    win.title(f"Chỉnh sửa điểm: {record[0]} - {record[2]}")
    win.geometry(query_size)

    ttk.Label(win, text="Điểm thi:").grid(row=0, column=0, padx=10, pady=10, sticky="w")
    grade_entry = ttk.Entry(win)
    grade_entry.insert(0, record[4])
    grade_entry.grid(row=0, column=1, padx=10, pady=10, sticky="ew")
    win.columnconfigure(1, weight=1)

    def update_grade():
        try:
            new_grade = float(grade_entry.get().strip())
        except:
            messagebox.showwarning("Chú ý", "Điểm phải là số!")
            return
        conn = connect_db()
        if conn:
            # ============================
            # I'M CHECKING HERE
            cursor = conn.cursor()
            try:
                cipher = PKCS1_OAEP.new(current_pubkey)
                encrypted_grade = cipher.encrypt(str(new_grade).encode('utf-8'))
                # Sử dụng stored procedure SP_INS_PUBLIC_BANGDIEM để insert/update điểm
                cursor.execute("EXEC SP_INS_PUBLIC_ENCRYPT_BANGDIEM ?, ?, ?, ?", (current_manv, record[0], record[2], encrypted_grade))
                conn.commit()
                messagebox.showinfo("Thành công", "Cập nhật điểm thành công!")
                win.destroy()
            # ============================
            except Exception as e:
                messagebox.showerror("Lỗi", f"Không thể cập nhật điểm: {e}")
            conn.close()

    ttk.Button(win, text="Cập nhật", command=update_grade, bootstyle="primary").grid(row=1, column=0, columnspan=2, pady=10)

def delete_grade(record):
    if not messagebox.askyesno("Xác nhận", "Bạn có chắc muốn xoá bản ghi này không?"):
        return
    conn = connect_db()
    if conn:
        cursor = conn.cursor()
        try:
            cursor.execute("DELETE FROM BANGDIEM WHERE MASV = ? AND MAHP = ?", (record[0], record[2]))
            conn.commit()
            messagebox.showinfo("Thành công", "Xoá điểm thành công!")
        except Exception as e:
            messagebox.showerror("Lỗi", f"Không thể xoá điểm: {e}")
        conn.close()

def add_grade():
    win = Toplevel()
    win.title("Thêm điểm mới")
    win.geometry(query_size)

    ttk.Label(win, text="Mã SV:").grid(row=0, column=0, padx=10, pady=10, sticky="w")
    masv_entry = ttk.Entry(win)
    masv_entry.grid(row=0, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Mã HP:").grid(row=1, column=0, padx=10, pady=10, sticky="w")
    mahp_entry = ttk.Entry(win)
    mahp_entry.grid(row=1, column=1, padx=10, pady=10, sticky="ew")

    ttk.Label(win, text="Điểm thi:").grid(row=2, column=0, padx=10, pady=10, sticky="w")
    grade_entry = ttk.Entry(win)
    grade_entry.grid(row=2, column=1, padx=10, pady=10, sticky="ew")

    win.columnconfigure(1, weight=1)

    def add_new_grade():
        masv = masv_entry.get().strip()
        mahp = mahp_entry.get().strip()
        try:
            grade_val = float(grade_entry.get().strip())
        except:
            messagebox.showwarning("Chú ý", "Điểm phải là số!")
            return
        if not masv or not mahp:
            messagebox.showwarning("Chú ý", "Vui lòng điền đầy đủ thông tin!")
            return
        conn = connect_db()
        if conn:
            cursor = conn.cursor()
            # ==============================
            # I'M CHECKING HERE
            try:
                cipher = PKCS1_OAEP.new(current_pubkey)
                encrypted_grade = cipher.encrypt(str(grade_val).encode('utf-8'))
                cursor.execute("EXEC SP_INS_PUBLIC_ENCRYPT_BANGDIEM ?, ?, ?, ?", (current_manv, masv, mahp, encrypted_grade))
                conn.commit()
                messagebox.showinfo("Thành công", "Thêm điểm thành công!")
                win.destroy()
            # ==============================
            except Exception as e:
                messagebox.showerror("Lỗi", f"Không thể thêm điểm: {e}")
            conn.close()

    ttk.Button(win, text="Thêm điểm", command=add_new_grade, bootstyle="success").grid(row=3, column=0, columnspan=2, pady=10)

# =================== QUẢN LÝ NHÂN VIÊN ======================
def manage_employee():
    class_win = Toplevel()
    class_win.title("Quản lý thông tin nhân viên")
    class_win.geometry(window_size)

    # Hiển thị thông tin cá nhân theo dạng:
    #  Mã NV = current_manv
    #  Họ tên = current_hoten
    #  Email = current_mail
    #  Lương = current_luong 
    frame = ttk.Frame(class_win)
    frame.grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
    class_win.rowconfigure(0, weight=1)
    class_win.columnconfigure(0, weight=1)

    ttk.Label(frame, text=f"Mã NV: {current_manv}").grid(row=0, column=0, padx=10, pady=5, sticky="w")

    ttk.Label(frame, text=f"Họ tên: {current_hoten}").grid(row=1, column=0, padx=10, pady=5, sticky="w")

    ttk.Label(frame, text=f"Email: {current_mail}").grid(row=2, column=0, padx=10, pady=5, sticky="w")

    ttk.Label(frame, text=f"Lương: {current_luong}").grid(row=3, column=0, padx=10, pady=5, sticky="w")

# =================== GIAO DIỆN ĐĂNG NHẬP/ĐĂNG KÝ ======================
# Giao diện chính sử dụng Notebook để chuyển đổi giữa đăng nhập và đăng ký
login_register_window = ttk.Window(themename="superhero")
login_register_window.title("Đăng nhập / Đăng ký Nhân viên")
login_register_window.geometry(window_size)

# Tạo Notebook chứa 2 tab: "Đăng nhập" và "Đăng ký"
notebook = ttk.Notebook(login_register_window)
login_frame = ttk.Frame(notebook)
register_frame = ttk.Frame(notebook)

notebook.add(login_frame, text="Đăng nhập")
notebook.add(register_frame, text="Đăng ký")
notebook.pack(expand=True, fill="both")

# =================== Giao diện Đăng nhập ======================
ttk.Label(login_frame, text="Mã nhân viên:", font=("Arial", 12)).pack(pady=10)
entry_username = ttk.Entry(login_frame)
entry_username.pack(fill="x", padx=20)

ttk.Label(login_frame, text="Mật khẩu:", font=("Arial", 12)).pack(pady=10)
entry_password = ttk.Entry(login_frame, show="*")
entry_password.pack(fill="x", padx=20)

ttk.Button(login_frame, text="Đăng nhập", command=login, bootstyle="primary").pack(pady=20)

# =================== Giao diện Đăng ký ======================
# Trong tab đăng ký, có thể hiện thông tin cơ bản và nút mở form đăng ký
ttk.Label(register_frame, text="Nếu bạn chưa có tài khoản, hãy đăng ký", font=("Arial", 12)).pack(pady=20)
ttk.Button(register_frame, text="Đăng ký ngay", command=register, bootstyle="primary").pack(pady=20)

login_register_window.mainloop()
