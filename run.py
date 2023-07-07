import tkinter
from tkinter import Tk, Frame, BOTH, RAISED, LEFT, CENTER, TOP, RIDGE

root = Tk()
root.geometry("1530x780")
root.resizable(True, True)
root.title("My First GUI")
root.configure(bg="black")
MAIN_FRAME = Frame(root, bg="black")
MAIN_FRAME.place(relx=0.0, rely=0.0, relwidth=1.0, relheight=1.0)
LOGIN_FRAME = Frame(root, bg="black")
LOGIN_FRAME.place(relx=0.0, rely=0.0, relwidth=1.0, relheight=1.0)
REGISTER_FRAME = Frame(root, bg="black")
REGISTER_FRAME.place(relx=0.0, rely=0.0, relwidth=1.0, relheight=1.0)
FORGET_PASSWORD_FRAME = Frame(root, bg="black")
FORGET_PASSWORD_FRAME.place(relx=0.0, rely=0.0, relwidth=1.0, relheight=1.0)
RESET_PASSWORD_FRAME = Frame(root, bg="black")
RESET_PASSWORD_FRAME.place(relx=0.0, rely=0.0, relwidth=1.0, relheight=1.0)
NEWS_FRAME = Frame(root, bg="black")
NEWS_FRAME.place(relx=0.0, rely=0.0, relwidth=1.0, relheight=1.0)

TRADING_FRAME = Frame(root, bg="black")
frames = [MAIN_FRAME, LOGIN_FRAME, REGISTER_FRAME, FORGET_PASSWORD_FRAME, RESET_PASSWORD_FRAME, NEWS_FRAME,
          TRADING_FRAME]



def show_frame(_frame):
    for fr in frames:
        fr.destroy()
        if fr == _frame:
            fr.pack(fill=BOTH, expand=1)
            fr.tkraise()
            fr.focus_set()
            root.update_idletasks()

    root.mainloop()


if __name__ == "__main__":
    show_frame(_frame=MAIN_FRAME)
