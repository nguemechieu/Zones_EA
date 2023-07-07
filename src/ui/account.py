class Account(object):
    def __init__(self, username: str, password: str):
        self.username = username
        self.password = password
        self.id = None
        self.token = None
