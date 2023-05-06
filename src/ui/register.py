import tkinter
from tkinter import Label, Entry, Button, Frame, messagebox


class Register(tkinter.Tk):
    def __init__(self, parent, controller):

        super().__init__()
        self.controller = controller
        self.parent = parent

        self.username_label = Label(master=self.master, text="Username")
        self.username_label.grid(row=0, column=0)
        self.username_entry = Entry(master=self.master)
        self.username_entry.grid(row=0, column=1)

        self.password_label = Label(master=self.master, text="Password")
        self.password_label.grid(row=1, column=0)
        self.password_entry = Entry(master=self.master)
        self.password_entry.grid(row=1, column=1)
        self.firstname_label = Label(master=self.master, text="Firstname")
        self.firstname_label.grid(row=2, column=0)
        self.firstname_entry = Entry(master=self.master)
        self.firstname_entry.grid(row=2, column=1)
        self.lastname_label = Label(master=self.master, text="Lastname")
        self.lastname_label.grid(row=3, column=0)
        self.lastname_entry = Entry(master=self.master)
        self.lastname_entry.grid(row=3, column=1)

        self.email_label = Label(master=self.master, text="Email")
        self.email_label.grid(row=4, column=0)
        self.email_entry = Entry(master=self.master)
        self.email_entry.grid(row=4, column=1)

        self.phone_label = Label(master=self.master, text="Phone Number")
        self.phone_label.grid(row=5, column=0)
        self.phone_entry = Entry(master=self.master)
        self.phone_entry.grid(row=5, column=1)

        self.register_button = Button(master=self.master, text='Register',
                                      command=lambda: self.register_user(
                                          self.username_entry.get(),
                                          self.password_entry.get(),
                                          self.firstname_entry.get(),
                                          self.lastname_entry.get(),
                                          self.email_entry.get(),
                                          self.phone_entry.get()
                                      ))

        self.register_button.grid(row=6, column=2, columnspan=3)
        self.cancel_button = Button(master=self.master, text='Cancel',
                                    command=lambda: self.controller.show_page('Login'))
        self.cancel_button.grid(row=6, column=0, columnspan=1)

    def register_user(self, param, param1, param2, param3, param4, param5):

        if param == "" or param1 == "" or param2 == "" or param3 == "" or param4 == "" or param5 == "":
            messagebox.showerror("Error", "All fields are required")
            return
        try:

            # create table users if it doesn't exist'

            self.controller.db.cur.execute("CREATE TABLE IF NOT EXISTS users (username VARCHAR(255),"
                                           "password VARCHAR(255), firstname VARCHAR(255),"
                                           "last_name VARCHAR(255),email VARCHAR(255),"

                                           "phone VARCHAR(255) ,_id INTEGER PRIMARY KEY AUTO_INCREMENT)")

            result = self.controller.db.cur.execute(
                "INSERT INTO users (username, password, firstname, last_name, email, phone) VALUES (%s, %s, %s, %s, "
                "%s, %s)",
                (param, param1, param2, param3, param4, param5)
            )
            self.controller.db.conn.commit()

            if result > 0:
                messagebox.showinfo("Success", "User registered successfully")
                self.controller.show_page('Login')
                return
            else:
                messagebox.showerror("Error", "User already exists")
                return

        except Exception as e:
            messagebox.showerror("Error", e)
