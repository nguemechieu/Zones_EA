import configparser
import math
import tkinter
from datetime import time, datetime

from src.Miscellaneous.ff_news import CheckNews
from src.db.db import Db
from src.modules.DwxZmqExecution import DwxZmqExecution
from src.modules.DwxZmqReporting import DwxZmqReporting
from src.zmq_connector import DwxZeromqConnector


class ZonesEa(tkinter.Tk):
    def __init__(self):
        tkinter.Tk.__init__(self)
        self.title("Zones EA                " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        self.conf = configparser.ConfigParser()
        self.conf.read(filenames='conf.INI')  # path of your .ini file

        self.db_password = "Bigboss307#"  # self.conf.get(section="MYSQL", option='db_password')
        self.db_host = "localhost"  # self.conf.get(section="MYSQL", option='db_host')
        self.db_user = "root"  # self.conf.get(section="MYSQL", option='db_user')

        self.db = Db(db_user=self.db_user,
                     db_host=self.db_host,
                     db_password=self.db_password)
        self.db.cur.execute("CREATE  DATABASE IF NOT EXISTS Zones_EA")
        self.db.cur.execute("USE Zones_EA")
        self.db.cur.execute(
            "CREATE TABLE IF NOT EXISTS Zones_EA.Zones (id INTEGER PRIMARY KEY AUTO_INCREMENT, name VARCHAR(255), "
            "buy_price DOUBLE, sell_price DOUBLE, buy_volume DOUBLE, sell_volume DOUBLE, "
            "buy_time TIMESTAMP, sell_time TIMESTAMP, buy_price_change DOUBLE, sell_price_change DOUBLE, "
            "buy_volume_change DOUBLE, sell_volume_change DOUBLE)")

        self.db.cur.execute("CREATE TABLE IF NOT EXISTS Zones_EA.Accounts (id INTEGER PRIMARY KEY AUTO_INCREMENT, "
                            "name VARCHAR(255), balance DOUBLE, currency VARCHAR(255))")
        self.db.cur.execute("CREATE TABLE IF NOT EXISTS Zones_EA.Orders (id INTEGER PRIMARY KEY AUTO_INCREMENT, "
                            "zone_id INTEGER, account_id INTEGER, symbol VARCHAR(255), "
                            "quantity DOUBLE, price DOUBLE, side VARCHAR(255), "
                            "created_at TIMESTAMP)")

        # Create tables candles to be used later
        self.db.cur.execute("CREATE TABLE IF NOT EXISTS Zones_EA.Candles (id INTEGER PRIMARY KEY AUTO_INCREMENT, "
                            "zone_id INTEGER, account_id INTEGER, symbol VARCHAR(255), "
                            "open_time TIMESTAMP, open_price DOUBLE, high_price DOUBLE, low_price DOUBLE, close_price "
                            "DOUBLE,"
                            "volume DOUBLE, created_at TIMESTAMP)")
        self.db.cur.execute("CREATE TABLE IF NOT EXISTS Zones_EA.Candles2 (id INTEGER PRIMARY KEY AUTO_INCREMENT, "
                            "zone_id INTEGER, account_id INTEGER, symbol VARCHAR(255), "
                            "open_time TIMESTAMP, open_price DOUBLE, high_price DOUBLE, low_price DOUBLE, close_price "
                            "DOUBLE,"
                            "volume DOUBLE, created_at TIMESTAMP)")

        self.confirm_zone = None
        self.buy_zone = None
        self.sell_zone = None
        self.cancel_zone = None

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

        self.geometry("1530x780")
        self.iconbitmap('../src/images/ZONES EA/slide1_Qwl_12.ico')
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
        self.viewing = tkinter.Menu(self.menu, tearoff=0)
        self.menu.add_cascade(label="View", menu=self.viewing)
        self.viewing.add_command(label="View zone", command=self.view_zone)
        self.viewing.add_command(label="Edit zone", command=self.edit_zone)
        self.viewing.add_command(label="Add zone", command=self.add_zone)

        self.menu.add_cascade(label="Charts", menu=self.chart)
        self.menu.add_cascade(label=" Data ", menu=self.market_data)

        self.menu.add_cascade(label="Tools", menu=self.tools)

        self.canvas = tkinter.Canvas(self, width=800, height=500, bg="black")

        self.canvas.place(x=400, y=50)
        self.canvas.configure(bg="black")
        self.canvas.configure(highlightbackground="green")
        self.canvas.configure(highlightcolor="white")
        self.canvas.create_rectangle(0, 0, 1530, 780, fill="black")

        self.account_info = tkinter.Label(self.master, text="========================  Account "
                                                            "Info============================"
                                          , bg="black", fg="white")
        self.account_info.place(x=500, y=0)
        self.account_info.configure(bg="black")
        self.account_info.configure(highlightbackground="green")
        self.account_info.configure(highlightcolor="white")
        self.account_info.configure(font=("Helvetica", 12))
        self.account_info.configure(highlightthickness=1)

        # CREATE TRADING BUTTONS
        self.grid = tkinter.Frame(self, bg="black")
        self.grid.place(x=0, y=0)
        self.grid.configure(bg="black")
        self.grid.configure(highlightbackground="green")
        self.grid.configure(highlightcolor="white")
        self.grid.configure(highlightthickness=1)
        self.grid.grid_columnconfigure(0, weight=1)
        self.grid.grid_columnconfigure(1, weight=1)
        self.grid.grid_columnconfigure(2, weight=1)

        self.sell = tkinter.Button(self.grid, text="Sell", command=self.sell_zone)
        self.sell.grid(row=0, column=0)
        self.sell.configure(bg="white")
        self.sell.configure(highlightbackground="green")
        self.sell.configure(highlightcolor="black")
        self.sell.configure(font=("Helvetica", 12))

        self.buy = tkinter.Button(self.grid, text="Buy", command=self.buy_zone)
        self.buy.grid(row=0, column=1)
        self.buy.configure(bg="white")
        self.buy.configure(highlightbackground="green")
        self.buy.configure(highlightcolor="black")
        self.price = 0
        self.buy.configure(font=("Helvetica", 12))
        self.buy.configure(highlightthickness=1)
        self.buy.configure(highlightcolor="white")
        self.buy.configure(highlightbackground="green")

        self.cancel = tkinter.Button(self.grid, text="Cancel", command=self.cancel_zone)
        self.cancel.grid(row=0, column=2)
        self.cancel.configure(bg="white")
        self.cancel.configure(highlightbackground="green")
        self.cancel.configure(highlightcolor="black")
        self.cancel.configure(font=("Helvetica", 12))

        self.grid.grid_rowconfigure(0, weight=1)
        self.grid.grid_rowconfigure(1, weight=1)
        self.grid.grid_rowconfigure(2, weight=1)

        self.conf = tkinter.Button(self.grid, text="Confirm", command=self.confirm_zone)

        self.zones_connect.subscribe_marketdata(
            _symbol=self.symbol
        )

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

                _price=0,
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
                _price=0,
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
        if currency_result == 1:
            return 1
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


if __name__ == '__main__':
    ZonesEa()
