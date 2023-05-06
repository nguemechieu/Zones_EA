import tkinter
from tkinter import messagebox

from src.db import db


class ForgotPassword(tkinter.Tk):
    def __init__(self, parent, controller):

        super().__init__()
        self.db = db.Db()
        self.root = self
        self.controller = controller
        self.parent = parent

        self.email_label = tkinter.Label(self.root, text="Email")
        self.email_label.grid(row=0, column=0)
        self.email_entry = tkinter.Entry(self.root, width=20, background='lightblue')
        self.email_entry.grid(row=0, column=1)
        self.email_button = tkinter.Button(self.root, text="Submit", command=lambda: self.submit())
        self.email_button.grid(row=3, column=0)

        self.go_back_button = tkinter.Button(self.root, text="Go Back",
                                             command=lambda: self.controller.show_page('Login'))
        self.go_back_button.grid(row=3, column=2)
        self.go_back_button.focus()

    def submit(self):
        email = self.email_entry.get()
        if not email:
            messagebox.showerror(title="Error", message="Please enter an email")
            return False
        try:
            self.db.cur.execute(
                "SELECT * FROM users WHERE email =?", (email
                                                       )
            )
            user = self.controller.cur.fetchone()
            if user:
                self.controller.show_page("Login")
                self.email_entry.delete(0, tkinter.END)
                self.email_entry.focus()

                # Send email to user
                self.controller.send_email(user[0], "Password Reset", "Password reset link")

                messagebox.showinfo(title="Success", message="Check your email for a password reset link")

                return True
            else:
                messagebox.showerror(title="Error", message="Invalid email")
                return False

        except Exception as e:
            messagebox.showerror(title="Error", message=str(e))
            return False
