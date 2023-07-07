import configparser
import time
from src.Telegram import TelegramBot
from src.db import Db
from src.modules.DwxZmqExecution import DwxZmqExecution
from src.zmq_connector import DwxZeromqConnector


class Trades(object):

    def __init__(self):
        self.db = Db()
        self.telegramBot = TelegramBot(token='2032573404:AAEfu_tvVukCibiYf8uUdi6NcDpSmbuj3Tg')

        self.zmqConnector = self.zones_connect = DwxZeromqConnector()
        self.execution = DwxZmqExecution(self.zmqConnector)

        self.conf = configparser.ConfigParser()

        self.db.cur.execute("CREATE TABLE IF NOT EXISTS Zones_EA.News (_id INTEGER PRIMARY KEY AUTO_INCREMENT" +

                            ", zone_id INTEGER, symbol VARCHAR(255), "
                            "name VARCHAR(255), description VARCHAR(255), "
                            "url VARCHAR(255), image_url VARCHAR(255), "
                            "created_at TIMESTAMP)")

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

        self.trade_id = 0
        self.user_id = 0
        self.product_id = 0
        self.quantity = 0
        self.price = 0
        self.time = 0
        self.status = 0
        self.type = 0
        self.order_id = 0
        self.order_type = 0
        self.order_status = 0
        self.commission = 0
        self.commission_currency = 0
        self.fee = 0
        self.fee_currency = 0
        self.trade_fee = 0
        self.stop_loss = 0
        self.take_profit = 0
        self.magic_number = 0
        self.slippage = 0
        self.expiration = 0
        self.created_at = 0
        self.symbol = ''

    def strategy(self, symbol: str):
        self.symbol = symbol
        self.db.cur.execute("USE Zones_EA")
        self.db.cur.execute("SELECT * FROM Zones_EA.Zones")
        self.db.cur.execute("SELECT * FROM Zones_EA.Accounts")
        self.db.cur.execute("SELECT * FROM Zones_EA.Orders")

        self.db.cur.execute("SELECT * FROM Zones_EA.News")
        self.db.cur.execute("SELECT * FROM Zones_EA.Candles")

        # Get Candles for the symbol

        self.db.cur.execute("SELECT * FROM Zones_EA.Candles WHERE symbol = '" + symbol + "'")
        # Determine the market structure
        self.symbol = symbol

        self.zones_connect.subscribe(self.symbol)
        self.zones_connect.subscribe_trades(self.symbol)
        self.zones_connect.subscribe_candles(self.symbol)
        self.zones_connect.subscribe_book_ticker(self.symbol)
        self.telegramBot.get_me()
        res = self.telegramBot.get_updates()
        self.chat_i = res['result'][0]['message']['chat']['id']
        self.telegramBot.send_message(chat_id=self.chat_i,
                                      message_text='Hello! I\'m Zones EA. I\'m here to help you to manage your zones trades.')
        chat = self.telegramBot.get_chat(chat_id=self.chat_i)
        self.telegramBot.send_message(chat_id=self.chat_i,
                                      message_text='I\'m here to help you to manage your zones trades.')
        print(self.chat_i)
        print(chat)
        print(res)

        chat_title = res['result'][0]['message']['chat']['title']
        print(chat_title)
        chat_type = res['result'][0]['message']['chat']['type']
        print(chat_type)
        message_id = res['result'][0]['message']['from']['id']
        print(message_id)
        first_name = res['result'][0]['message']['from']['first_name']
        print(first_name)
        is_bot = res['result'][0]['message']['from']['is_bot']
        print(is_bot)

        if is_bot == True:
            self.telegramBot.send_message(chat_id=self.chat_i,

                                          message_text="Hello! I'm Zones EA. I'm here to help you to manage your zones trades.")

    def open_trade(self, symbol: str,
                   price: float,
                   quantity: float,
                   order_type: int,
                   stop_loss: float,
                   take_profit: float,
                   slippage: float,
                   magic_number: float,
                   expiration: int):
        self.symbol = symbol
        self.price = price
        self.quantity = quantity
        self.order_type = order_type
        self.stop_loss = stop_loss
        self.take_profit = take_profit
        self.slippage = slippage
        self.magic_number = magic_number
        self.expiration = expiration
        self.created_at = time.time()
        self.status = 1

        self.trade_id = self.zones_connect.open_trade(self.symbol,
                                                      self.price,
                                                      self.quantity,
                                                      self.order_type,
                                                      self.stop_loss,
                                                      self.take_profit,
                                                      self.slippage,
                                                      self.magic_number,
                                                      self.expiration)

    def close_trade(self, trade_id: int):
        self.zones_connect.close_trade(trade_id)
        self.status = 0
        self.trade_id = 0

    def get_all_trades(self):
        return self.zones_connect.get_all_trades()

    def get_account_info(self):
        return self.zmqConnector._DWX_MTX_GET_ACCOUNT_INFO_()

    def get_trade_history(self):
        return self.zones_connect.get_trade_history()

    def get_statistics(self):
        return self.zones_connect.get_statistics()

    def get_live_price(self, symbol: str):
        return self.zones_connect.get_live_price(symbol)

    def get_order_history(self):
        return self.zones_connect.get_order_history()

    def get_open_orders(self):
        return self.zones_connect.get_open_orders()
