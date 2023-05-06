import math
import tkinter
from datetime import time

from src.Miscellaneous.ff_news import CheckNews
from src.modules.DwxZmqExecution import DwxZmqExecution
from src.modules.DwxZmqReporting import DwxZmqReporting
from src.zmq_connector import DwxZeromqConnector


class ZonesEa(tkinter.Tk):
    def __init__(self):
        tkinter.Tk.__init__(self)
        # zero mq binding

        self.zones_connect = DwxZeromqConnector(self)

        self.update_account_balance = None
        self.symbol = 'AUDUSD'
        self.tick_data = None
        self.market_data = None
        self.copymenu_ = None
        self.check_news = None
        self.tools = None
        self.chart = None
        self.view = None
        self.insertmenu = None
        self.save = None
        self.sign_out = None
        self.sign_in = None
        self.save_file = None
        self.open_file = None
        self.lot = 0.01
        self.view_zone = None
        self.edit_zone = None
        self.add_zone = None
        self.redo = None
        self.undo = None
        self.delete_zone = None
        self.title("Zones  EA")
        self.geometry("1530x780")
        self.iconbitmap("../src/images/zones_ea.ico")
        self.resizable(True, True)
        self.configure(bg="blue")
        self.configure(highlightbackground="blue")
        self.configure(highlightcolor="white")
        self.configure(highlightthickness=1)

        self.menu = tkinter.Menu(self)
        self.config(menu=self.menu)
        self.filename = tkinter.Menu(self.menu, tearoff=0)
        self.menu.add_cascade(label="File", menu=self.filename)
        self.filename.add_separator()
        self.filename.add_command(label="Open file", command=self.open_file)
        self.filename.add_separator()
        self.filename.add_command(label="Save", command=self.save)
        self.filename.add_separator()
        self.filename.add_command(label="Save file ", command=self.save_file)
        self.filename.add_separator()
        self.filename.add_command(label="Sign in", command=self.sign_in)
        self.filename.add_separator()
        self.filename.add_command(label="Sign out", command=self.sign_out)
        self.filename.add_separator()
        self.filename.add_command(label="Exit", command=self.quit)
        self.filename.add_separator()
        self.editmenu = tkinter.Menu(self.menu, tearoff=0)
        self.menu.add_cascade(label="Edit", menu=self.editmenu)
        self.editmenu.add_cascade(label="Copy ", menu=self.copymenu_)
        self.editmenu.add_command(label="Undo", command=self.undo)
        self.editmenu.add_command(label="Redo", command=self.redo)
        self.editmenu.add_separator()
        self.menu.add_cascade(label="Insert ", menu=self.insertmenu)

        self.viewmenu = tkinter.Menu(self.menu, tearoff=0)
        self.menu.add_cascade(label="View", menu=self.viewmenu)
        self.viewmenu.add_command(label="View zone", command=self.view_zone)
        self.viewmenu.add_command(label="Edit zone", command=self.edit_zone)
        self.viewmenu.add_command(label="Add zone", command=self.add_zone)

        self.menu.add_cascade(label="Charts", menu=self.chart)
        self.menu.add_cascade(label=" Data ", menu=self.market_data)

        self.menu.add_cascade(label="Tools", menu=self.tools)

        self.canvas = tkinter.Canvas(self, width=800, height=500, bg="black")

        self.canvas.place(x=400, y=50)
        self.canvas.configure(bg="black")
        self.canvas.configure(highlightbackground="green")
        self.canvas.configure(highlightcolor="white")
        self.canvas.create_rectangle(0, 0, 1030, 500, fill="black")

        self.account_info = tkinter.Label(self.master, text="========================  Account "
                                                            "Info============================"
                                          , bg="black", fg="white")
        self.account_info.place(x=300, y=0)
        self.account_info.configure(bg="black")
        self.account_info.configure(highlightbackground="green")
        self.account_info.configure(highlightcolor="white")
        self.account_info.configure(font=("Helvetica", 12))
        self.account_info.configure(highlightthickness=1)
        self.account_info.configure(text="Account Info")
        self.account_info_data = self.zones_connect.get_account_info()

        self.account_balance = tkinter.Label(self.master, text="Balance ", bg="Green", fg="red")
        self.account_balance.place(x=10, y=100)
        self.account_balance.configure(bg="Green")
        self.account_balance.configure(highlightbackground="green")
        self.account_balance.configure(highlightcolor="white")
        self.account_balance.configure(font=("Helvetica", 12))
        self.account_balance.configure(highlightthickness=1)
        self.account_balance.configure(text="Balance")

        self.account_balance_label = tkinter.Label(self.master, text="Balance", bg="black", fg="red")
        self.account_balance_label.place(x=0, y=60)
        self.account_balance_label.configure(bg="black")
        self.account_balance_label.configure(highlightbackground="green")
        self.account_balance_label.configure(highlightcolor="white")
        self.account_balance_label.configure(font=("Helvetica", 12))
        self.account_balance_label.configure(highlightthickness=1)
        self.account_balance_label.configure(text="Balance")
        self.account_balance_entry = tkinter.Entry(self.master)
        self.account_balance_entry.place(x=0, y=70)
        self.account_balance_entry.configure(bg="black")

        self.symbol_info = tkinter.Label(self.master, text="Symbol Info", bg="black", fg="red")
        self.symbol_info.place(x=0, y=20)
        self.symbol_info.configure(bg="black")
        self.symbol_info.configure(highlightbackground="green")
        self.symbol_info.configure(highlightcolor="white")
        self.symbol_info.configure(font=("Helvetica", 12))
        self.symbol_info.configure(highlightthickness=1)

        self.price = self.zones_connect.send_track_prices_request(_symbols=self.symbol)

        self.zones_connect.subscribe_marketdata(
            _symbol=self.symbol
        )
        self.zones_connect.send_track_rates_request()

        self.strategy = DwxZeromqConnector(self)
        self.strategy.get_all_open_trades()

        self.reporting = DwxZmqReporting(self)

        self.execute = DwxZmqExecution(self)

        self.zones_connect.generate_default_order_dict()
        self.zones_connect.get_account_info()

        if self.trade_signal() == 1:
            self.zones_connect.send_command(
                _symbol='AUDUSD',

                _price=0
                ,
                _lots=self.lot,
                _action='BUY',
                _type=0,
                _ticket=math.floor(
                    time.max.second * 1000
                ),
                _magic=math.floor(time.min.second * 1000)

            )

        elif self.trade_signal() == 2:
            self.zones_connect.send_command(
                _symbol='AUDUSD',

                _price=self.price,
                _lots=self.lot,
                _action='SELL',
                _type=0,
                _ticket=math.floor(
                    time.max.second * 1000),
                _magic=math.floor(time.min.second * 1000))

        elif self.trade_signal() == 3:
            self.zones_connect.send_command(
                _symbol='AUDUSD',

                _price=self.zones_connect.send_track_rates_request(
                    _instruments=['AUDUSD']),
                _magic=math.floor(time.min.second * 1000))

        elif self.trade_signal() == 4:
            self.zones_connect.send_command(
                _symbol='AUDUSD',

                _price=self.price

                ,
                _lots=self.lot,
                _action='SELLLIMIT',
                _type=4,
                _ticket=math.floor(
                    time.max.second * 1000),
                _magic=math.floor(time.min.second * 1000), _sl=50, _tp=100)

        elif self.trade_signal() == 5:
            self.zones_connect.send_command(
                _symbol='AUDUSD',
                _price=self.zones_connect.send_track_rates_request(_instruments=['AUDUSD']),
                _lots=self.lot,
                _action='BUYSTOP',
                _type=5,
                _ticket=math.floor(
                    time.max.second * 1000),
                _magic=math.floor(time.min.second * 1000), _sl=50, _tp=100)

        elif self.trade_signal() == 6:
            self.zones_connect.send_command(
                _symbol='AUDUSD',
                _price=self.price,
                _lots=self.lot,
                _action='SELLSTOP',
                _type=6,
                _ticket=math.floor(
                    time.max.second * 1000),
                _magic=math.floor(time.min.second * 1000), _sl=50, _tp=100)

        self.mainloop()

    def trade_signal(self, symbol: str = 'EURUSD'):
        # create instance with default values
        # the downloaded news information will be stored in a news sub folder
        # if the folder does not exit it will be created
        news = CheckNews(
            url='https://nfs.faireconomy.media/ff_calendar_thisweek.xml?version=45f4bf06b3af96b68bf3dd03db821ab6',
            update_in_minutes=240,
            minutes_before_news=480,
            minutes_after_news=60)

        # check for news for a currency
        currency_result = news.check_currency(currency='EUR')
        print(currency_result)
        print('')

        # check for news for an instrument
        instrument_result = news.check_instrument(instrument='EURUSD')
        print(instrument_result)
        print('')

        # get the next x news items
        news_items = news.get_next_x_news_items(5)
        print(news_items)
        print('')
        self.zones_connect.send_command(
            _symbol=symbol,
            _price=self.zones_connect.send_command(_symbol=symbol),
            _lots=self.lot,
            _action='BUY',
            _type=0,
            _ticket=math.floor(
                time.max.second * 1000
            ),
            _magic=math.floor(time.min.second * 1000)

        )
        return 3


if __name__ == "__main__":
    ZonesEa()
