import tkinter
from tkinter import Button, messagebox


class Login(tkinter.Frame):
    def __init__(self, controller):
        super().__init__()
        self.parent = self.master
        self.controller = controller
        self.grid(padx=400, pady=150)
        self.error_label = None
        self.frames = {}
        self.error = tkinter.StringVar()
        self.on_closing = None
        self.login_frame = None
        self.username = tkinter.StringVar()
        self.password = tkinter.StringVar()
        self.username.set("Enter your username")
        self.password.set("Enter your password")
        self.username_label = tkinter.Label(self.master, textvariable=self.username)
        self.password_label = tkinter.Label(self.master, textvariable=self.password)
        self.username_label.grid(row=1, column=0)
        self.password_label.grid(row=2, column=0)
        Button(self.parent
               , text="Login", command=lambda: self.verify_user).grid(row=3, column=1)

        Button(self.master, text="Register", command=lambda: self.controller.show_pages('Register')).grid(row=3,
                                                                                                          column=0)
        Button(self.master, text="Forgot Password",
               command=lambda: self.controller.show_pages('ForgotPassword')).grid(row=4,
                                                                                  column=1
                                                                                  )

    def verify_user(self):
        username = self.username.get()
        password = self.password.get()

        if username == "" or password == "":
            messagebox.showerror("Error", "Please enter username and password")
            return False

        try:

            self.controller.db.cur.execute("USE " + self.controller.db.database)
            self.controller.db.cur.execute("SELECT * FROM users WHERE username = %s AND password = %s", (username,
                                                                                                         password))
            result = self.controller.db.cur.fetchone()
            if result and username == self.controller.username.get() and password == self.controller.passwordx.get():
                self.controller.username.set(username)
                self.controller.passwordx.set(password)
                self.controller.show_pages(page='Home')

                return True
            else:
                messagebox.showerror("Error", "Invalid username or password")
                return False

        except Exception as e:
            messagebox.showerror("Error", e.args[0])
        return False
