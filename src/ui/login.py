import tkinter
from tkinter import Label, Entry, Button, messagebox


class Login(tkinter.Tk):
    def __init__(self, parent, controller):

        super().__init__()

        self.parent = parent
        self.controller = controller

        self.username_label = Label(master=self.master, text="Username : ")
        self.username_label.grid(row=0, column=1)
        self.username_entry = Entry(master=self.master, bg="lightblue")
        self.username_entry.grid(row=0, column=2)
        self.password_label = Label(master=self.master, text="Password :")
        self.password_label.grid(row=1, column=1)
        self.password_entry = Entry(master=self.master, bg="lightblue")
        self.password_entry.grid(row=1, column=2)
        self.login_button = Button(master=self.master, text="Login",
                                   command=lambda: self.verify_user(
                                       self.username_entry.get(),
                                       self.password_entry.get()
                                   ))
        self.login_button.grid(row=4, column=4)

        self.register_button = Button(master=self.master, text="Register",
                                      command=lambda: self.controller.show_page(page_name='Register'))
        self.register_button.grid(row=4, column=1)

        self.forgot_password_button = Button(master=self.master, text="Forgot Password",
                                             command=lambda: self.controller.show_page(page_name='ForgotPassword'))
        self.forgot_password_button.grid(row=6, column=2)

    def verify_user(self, username, password):
        if username == "" or password == "":
            messagebox.showerror("Error", "Please enter username and password")
            return False

        try:

            self.controller.db.cur.execute("USE  Zones_EA")
            self.controller.db.cur.execute("SELECT * FROM users WHERE username = %s AND password = %s", (username,
                                                                                                         password))
            result = self.controller.db.cur.fetchone()
            if result:
                self.controller.show_page(page_name='Home')

                return True
            else:
                messagebox.showerror("Error", "Invalid username or password")
                return False

        except Exception as e:
            messagebox.showerror("Error", e)

        pass
